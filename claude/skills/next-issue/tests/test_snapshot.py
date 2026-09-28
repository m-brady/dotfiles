import json, os, pathlib, subprocess, tempfile, unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
SCRIPT=ROOT/"scripts"/"backlog_snapshot.py"
FIXTURE=ROOT/"tests"/"fixture.json"

class SnapshotTests(unittest.TestCase):
    def run_json(self,*args):
        return json.loads(subprocess.run(["python3",str(SCRIPT),*map(str,args)],check=True,text=True,capture_output=True).stdout)

    def test_collect_preserves_and_classifies(self):
        data=self.run_json("collect","--fixture",FIXTURE)
        self.assertEqual(data["eligibleIssueNumbers"],[12,11])
        self.assertEqual(data["excludedIssues"][0]["reasons"],["tracking"])
        issue=next(i for i in data["issues"] if i["number"]==12)
        self.assertEqual(issue["labels"],["bug"])
        self.assertEqual(issue["comments"][0]["body"],"full comment")
        self.assertEqual(data["inflight"]["issuesWithOpenPR"][0]["issue"],12)
        self.assertTrue(data["landedLeads"][0]["closingLanguage"])
        self.assertIn("body",data["inflight"]["openPRs"][0])
        self.assertEqual(data["taxonomy"]["labels"][0]["name"],"bug")
        self.assertEqual(data["meta"]["defaultBranch"],"main")

    def test_saved_summary_reclassifies_and_show_batches(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pathlib.Path(tmp)/"snapshot.json"
            result=subprocess.run(["python3",str(SCRIPT),"collect","--fixture",str(FIXTURE),"--output",str(path)],check=True,text=True,capture_output=True)
            self.assertEqual(result.stdout,"")
            summary=self.run_json("summary",path,"--also-exclude","waiting")
            self.assertEqual([x["number"] for x in summary["candidates"]],[12])
            self.assertEqual(summary["meta"]["counts"]["excluded"],2)
            shown=self.run_json("show",path,12,11)
            self.assertEqual({x["number"] for x in shown["issues"]},{11,12})
            self.assertEqual(shown["openPRs"][0]["number"],8)
            with_pr=self.run_json("show",path,"--prs",7)
            self.assertEqual(with_pr["mergedPRs"][0]["body"],"Would also fix #11")
            missing=subprocess.run(["python3",str(SCRIPT),"show",str(path),"--prs","99"],text=True,capture_output=True)
            self.assertNotEqual(missing.returncode,0)
            self.assertIn("PRs absent from snapshot: #99",missing.stderr)

    def test_live_collect_lists_issues_once_and_reads_are_offline(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp=pathlib.Path(tmp); log=tmp/"calls"; gh=tmp/"gh"; snapshot=tmp/"snapshot.json"
            gh.write_text("""#!/usr/bin/env python3
import json,os,sys
with open(os.environ['GH_TEST_LOG'],'a') as f: f.write(' '.join(sys.argv[1:])+'\\n')
a=sys.argv[1:]
if a[:2]==['repo','view']:
  assert a[2]=='acme/widget' and '--repo' not in a
  out={'nameWithOwner':'acme/widget','defaultBranchRef':{'name':'main'}}
elif a[:2]==['issue','list']: out=[]
elif a[:2]==['pr','list']: out=[]
elif a[:2]==['label','list']: out=[]
elif a[:1]==['api']: out=[]
else: raise SystemExit(2)
print(json.dumps(out))
"""); gh.chmod(0o755)
            env={**os.environ,"PATH":f"{tmp}:{os.environ['PATH']}","GH_TEST_LOG":str(log)}
            subprocess.run(["python3",str(SCRIPT),"collect","--repo","acme/widget","--output",str(snapshot)],check=True,env=env)
            calls=log.read_text().splitlines()
            self.assertEqual(sum(line.startswith("issue list") for line in calls),1)
            before=len(calls)
            subprocess.run(["python3",str(SCRIPT),"summary",str(snapshot)],check=True,env=env,capture_output=True)
            subprocess.run(["python3",str(SCRIPT),"show",str(snapshot)],check=True,env=env,capture_output=True)
            self.assertEqual(len(log.read_text().splitlines()),before)

    def test_gh_error_surfaces_stderr(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp=pathlib.Path(tmp); gh=tmp/"gh"
            gh.write_text("#!/bin/sh\necho 'authentication required' >&2\nexit 1\n"); gh.chmod(0o755)
            env={**os.environ,"PATH":f"{tmp}:{os.environ['PATH']}"}
            result=subprocess.run(["python3",str(SCRIPT),"collect","--repo","acme/widget"],text=True,capture_output=True,env=env)
            self.assertNotEqual(result.returncode,0)
            self.assertIn("authentication required",result.stderr)
            self.assertNotIn("Traceback",result.stderr)

if __name__ == "__main__": unittest.main()
