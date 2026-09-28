#!/usr/bin/env python3
"""Collect and inspect one reusable GitHub backlog snapshot."""
import argparse, concurrent.futures, datetime as dt, json, re, subprocess, sys

DEFAULT_EXCLUDES = "wontfix,duplicate,invalid,not planned,anti-goal,deferred,on-hold,on hold,blocked,icebox,backlog,parked,stale,tracking,epic,umbrella"
LIMITS = {"issues": 500, "openPRs": 100, "mergedPRs": 400}
REF_RE = re.compile(r"#(\d+)")
CLOSE_RE = re.compile(r"(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s*:?\s*#(\d+)", re.I)

def gh_json(args):
    result = subprocess.run(["gh", *args], text=True, capture_output=True)
    if result.returncode:
        detail=(result.stderr or result.stdout or "unknown error").strip()
        raise SystemExit(f"gh {' '.join(args[:2])} failed: {detail}")
    try: return json.loads(result.stdout)
    except json.JSONDecodeError as error: raise SystemExit(f"gh {' '.join(args[:2])} returned invalid JSON: {error}")

def needles(value): return [x.strip().lower() for x in value.split(",") if x.strip()]
def names(items, key): return [x.get(key, "") if isinstance(x, dict) else str(x) for x in items or []]
def refs(text): return sorted({int(x) for x in REF_RE.findall(text or "")})
def closes(text): return sorted({int(x) for x in CLOSE_RE.findall(text or "")})

def annotate(record):
    result = dict(record)
    text = f"{result.get('title', '')} {result.get('body') or ''}"
    result.update(refs=refs(text), closes=closes(text))
    return result

def build(raw, drop, days, include_all=False):
    issues = []
    for source in raw["issues"]:
        issue = dict(source)
        issue["labels"] = names(issue.get("labels"), "name")
        issue["assignees"] = names(issue.get("assignees"), "login")
        milestone = issue.get("milestone")
        issue["milestone"] = milestone.get("title") if isinstance(milestone, dict) else milestone
        issue["commentCount"] = len(issue.get("comments") or [])
        lower = [label.lower() for label in issue["labels"]]
        issue["excludedBy"] = [] if include_all else sorted({n for n in drop if any(n in label for label in lower)})
        issues.append(issue)
    open_numbers = {i["number"] for i in issues}
    open_prs = [annotate(x) for x in raw["openPRs"]]
    merged_prs = [annotate(x) for x in raw["mergedPRs"]]
    commits = [annotate(x) for x in raw.get("commits", [])]
    linked = {i["number"]: {p.get("number") for p in i.get("closedByPullRequestsReferences") or []} for i in issues}
    inflight = []
    landed = []
    for number in sorted(open_numbers):
        hits = [p for p in open_prs if number in p["refs"] or p.get("number") in linked[number]]
        if hits:
            hit_numbers={p.get("number") for p in hits}
            inflight.append({"issue": number, "linked": bool(linked[number] & hit_numbers), "prs": [{k:p.get(k) for k in ("number","title","isDraft","url")} for p in hits]})
        evidence = []
        for kind, records in (("merged-pr", merged_prs), ("commit", commits)):
            for record in records:
                if number in record["refs"]:
                    evidence.append({"type":kind, "ref":f"#{record['number']}" if kind == "merged-pr" else record.get("sha","")[:9], "title":record.get("title",""), "at":record.get("mergedAt") if kind == "merged-pr" else record.get("at"), "closing":number in record["closes"]})
        if evidence:
            landed.append({"issue":number, "closingLanguage":any(e["closing"] for e in evidence), "evidence":evidence})
    excluded = [i for i in issues if i["excludedBy"]]
    eligible = [i for i in issues if not i["excludedBy"]]
    counts = {"openIssues":len(issues), "eligible":len(eligible), "excluded":len(excluded), "openPRs":len(open_prs), "mergedPRs":len(merged_prs), "commits":len(commits)}
    return {"schemaVersion":1, "collectedAt":raw.get("collectedAt") or dt.datetime.now(dt.timezone.utc).isoformat(),
      "meta":{"repo":raw.get("repo"), "defaultBranch":raw.get("defaultBranch"), "days":days, "limits":LIMITS, "possiblyTruncated":{k:counts[k if k != "issues" else "openIssues"] >= v for k,v in LIMITS.items()}, "counts":counts, "excludeNeedles":[] if include_all else drop},
      "taxonomy":{"labels":raw.get("labels",[]),"openMilestones":raw.get("milestones",[])},
      "issues":sorted(issues,key=lambda i:i["number"],reverse=True), "eligibleIssueNumbers":[i["number"] for i in eligible],
      "excludedIssues":[{"number":i["number"],"labels":i["labels"],"reasons":i["excludedBy"]} for i in excluded],
      "inflight":{"issuesWithOpenPR":inflight,"openPRs":open_prs}, "landedLeads":landed, "mergedPRs":merged_prs, "commits":commits}

def collect(args):
    cutoff=(dt.datetime.now(dt.timezone.utc)-dt.timedelta(days=args.days)).date().isoformat()
    repo=["--repo",args.repo] if args.repo else []
    repo_info=gh_json(["repo","view",*([args.repo] if args.repo else []),"--json","nameWithOwner,defaultBranchRef"])
    repo_name=args.repo or repo_info["nameWithOwner"]
    requests={
      "issues":["issue","list",*repo,"--state","open","--limit","500","--json","number,title,url,createdAt,updatedAt,comments,labels,milestone,assignees,body,closedByPullRequestsReferences"],
      "openPRs":["pr","list",*repo,"--state","open","--limit","100","--json","number,title,body,isDraft,updatedAt,headRefName,url"],
      "mergedPRs":["pr","list",*repo,"--state","merged","--limit","400","--search",f"merged:>={cutoff}","--json","number,title,body,mergedAt,url"],
      "labels":["label","list","--repo",repo_name,"--limit","1000","--json","name,description,color"],
      "milestones":["api",f"repos/{repo_name}/milestones?state=open&per_page=100"]}
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        futures={key:pool.submit(gh_json,command) for key,command in requests.items()}
        fetched={key:future.result() for key,future in futures.items()}
    raw={"repo":repo_name, "defaultBranch":(repo_info.get("defaultBranchRef") or {}).get("name"), **fetched, "commits":[]}
    if not args.repo and raw["defaultBranch"]:
        check=subprocess.run(["git","rev-parse","--verify","--quiet",f"origin/{raw['defaultBranch']}"],text=True,capture_output=True)
        ref=check.stdout.strip() or subprocess.run(["git","rev-parse","--verify","--quiet",raw["defaultBranch"]],text=True,capture_output=True).stdout.strip()
        if ref:
            log=subprocess.run(["git","log",ref,f"--since={args.days} days ago","--format=%H%x1f%s%x1f%b%x1e"],text=True,capture_output=True,check=True).stdout
            for row in log.split("\x1e"):
                if not row.strip(): continue
                parts=row.strip().split("\x1f",2)
                raw["commits"].append({"sha":parts[0],"title":parts[1] if len(parts)>1 else "","body":parts[2] if len(parts)>2 else "","at":None})
    return build(raw, needles(args.exclude), args.days, args.all)

def load(path):
    with (sys.stdin if path == "-" else open(path)) as stream: return json.load(stream)

def reclassify(snapshot, drop, include_all):
    for issue in snapshot["issues"]:
        lower=[label.lower() for label in issue["labels"]]
        issue["excludedBy"]=[] if include_all else sorted({n for n in drop if any(n in label for label in lower)})
    excluded=[i for i in snapshot["issues"] if i["excludedBy"]]
    snapshot["eligibleIssueNumbers"]=[i["number"] for i in snapshot["issues"] if not i["excludedBy"]]
    snapshot["excludedIssues"]=[{"number":i["number"],"labels":i["labels"],"reasons":i["excludedBy"]} for i in excluded]
    snapshot["meta"]["counts"]["eligible"]=len(snapshot["eligibleIssueNumbers"])
    snapshot["meta"]["counts"]["excluded"]=len(excluded)
    snapshot["meta"]["excludeNeedles"]=[] if include_all else drop
    return snapshot

def main():
    parser=argparse.ArgumentParser(); sub=parser.add_subparsers(dest="command",required=True)
    p=sub.add_parser("collect"); p.add_argument("--repo"); p.add_argument("--days",type=int,default=21); p.add_argument("--all",action="store_true"); p.add_argument("--exclude",default=DEFAULT_EXCLUDES); p.add_argument("--also-exclude",default=""); p.add_argument("--fixture",help=argparse.SUPPRESS); p.add_argument("--output")
    p=sub.add_parser("summary"); p.add_argument("snapshot"); p.add_argument("--all",action="store_true"); p.add_argument("--exclude"); p.add_argument("--also-exclude",default="")
    p=sub.add_parser("show"); p.add_argument("snapshot"); p.add_argument("number",type=int,nargs="*"); p.add_argument("--prs",type=int,nargs="*",default=[])
    args=parser.parse_args()
    if args.command == "collect":
        args.exclude=",".join(filter(None,[args.exclude,args.also_exclude]))
        if args.fixture:
            with open(args.fixture) as stream: raw=json.load(stream)
            result=build(raw,needles(args.exclude),args.days,args.all)
        else: result=collect(args)
        encoded=json.dumps(result,indent=2)+"\n"
        if args.output:
            with open(args.output,"w") as stream: stream.write(encoded)
        else: sys.stdout.write(encoded)
    elif args.command == "summary":
        d=load(args.snapshot)
        base=args.exclude if args.exclude is not None else ",".join(d["meta"]["excludeNeedles"])
        d=reclassify(d,needles(",".join(filter(None,[base,args.also_exclude]))),args.all)
        wanted=set(d["eligibleIssueNumbers"])
        candidates=[{k:i.get(k) for k in ("number","title","url","createdAt","updatedAt","commentCount","labels","milestone","assignees","excludedBy")} for i in d["issues"] if i["number"] in wanted]
        compact_prs=[{k:p.get(k) for k in ("number","title","isDraft","updatedAt","headRefName","url","refs")} for p in d["inflight"]["openPRs"]]
        result={"schemaVersion":d["schemaVersion"],"collectedAt":d["collectedAt"],"meta":d["meta"],"taxonomy":d.get("taxonomy",{}),"candidates":candidates,"excludedIssues":d["excludedIssues"],"issuesWithOpenPR":d["inflight"]["issuesWithOpenPR"],"openPRs":compact_prs,"landedLeads":d["landedLeads"]}; print(json.dumps(result,indent=2))
    else:
        d=load(args.snapshot); wanted=set(args.number); found=[i for i in d["issues"] if i["number"] in wanted]; missing=sorted(wanted-{i["number"] for i in found})
        if missing: parser.error("issues absent from snapshot: "+", ".join(f"#{n}" for n in missing))
        pr_numbers=set(args.prs)
        formal_numbers={pr.get("number") for link in d["inflight"]["issuesWithOpenPR"] if link["issue"] in wanted for pr in link["prs"]}
        full_open=[p for p in d["inflight"]["openPRs"] if p.get("number") in pr_numbers|formal_numbers or wanted.intersection(p.get("refs",[]))]
        full_merged=[p for p in d.get("mergedPRs",[]) if p.get("number") in pr_numbers]
        found_prs={p.get("number") for p in full_open+full_merged}
        missing_prs=sorted(pr_numbers-found_prs)
        if missing_prs: parser.error("PRs absent from snapshot: "+", ".join(f"#{n}" for n in missing_prs))
        print(json.dumps({"issues":found,"openPRs":full_open,"mergedPRs":full_merged,"landedLeads":[x for x in d["landedLeads"] if x["issue"] in wanted]},indent=2))
if __name__ == "__main__": main()
