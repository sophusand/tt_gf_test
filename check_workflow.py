#!/usr/bin/env python3
"""
Check GitHub Actions workflow status for tt_gf_test
Usage: python3 check_workflow.py [--browser] [--all]
"""

import json
import subprocess
import sys
from urllib.request import urlopen
from urllib.error import URLError

def get_workflow_status(show_all=False):
    repo = "sophusand/tt_gf_test"
    api_url = f"https://api.github.com/repos/{repo}/actions/runs"
    
    print("📋 Fetching latest workflow runs...\n")
    
    try:
        # Get latest runs
        with urlopen(f"{api_url}?per_page=5") as response:
            data = json.loads(response.read().decode())
        
        if not data.get('workflow_runs'):
            print("❌ No workflow runs found")
            return
        
        # Show only latest or all
        runs_to_show = data['workflow_runs'] if show_all else data['workflow_runs'][:1]
        
        for run in runs_to_show:
            run_id = run['id']
            
            print(f"✅ Run ID: {run_id}")
            print(f"📝 Workflow: {run['name']} | Commit: {run['display_title']}")
            print(f"🔄 Status: {run['status']} | Conclusion: {run['conclusion']}")
            print(f"📅 Created: {run['created_at']}")
            print(f"🔗 View: https://github.com/{repo}/actions/runs/{run_id}\n")
            
            # Get jobs
            with urlopen(f"{api_url}/{run_id}/jobs") as response:
                jobs_data = json.loads(response.read().decode())
            
            print("📊 Job Status:")
            for job in jobs_data.get('jobs', []):
                status_icon = {
                    'success': '✅',
                    'failure': '❌',
                    'skipped': '⏭️ ',
                    'completed': '✔️ '
                }.get(job['conclusion'], '⏳')
                
                print(f"  {status_icon} {job['name']}: {job['status']} ({job['conclusion']})")
                
                # If there's a failure, show failing steps
                if job['conclusion'] == 'failure':
                    for step in job.get('steps', []):
                        if step.get('conclusion') == 'failure':
                            print(f"     ❌ Step: {step['name']}")
            
            print()
        
        # Open browser if requested
        if "--browser" in sys.argv or "-b" in sys.argv:
            print(f"🌐 Opening latest workflow in browser...")
            subprocess.run(["open", f"https://github.com/{repo}/actions/runs/{data['workflow_runs'][0]['id']}"])
    
    except URLError as e:
        print(f"❌ Network error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    show_all = "--all" in sys.argv or "-a" in sys.argv
    get_workflow_status(show_all)
