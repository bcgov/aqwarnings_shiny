### Using Github Desktop to publish warnings via GitHub Pages

1. Open GitHub Desktop, ensure the current repository is "aqwarnings". If you don't have this repository, clone it from [https://github.com/bcgov/aqwarnings](https://github.com/bcgov/aqwarnings).

2. Ensure the Current branch is showing "main" and click "Fetch origin" (tab along the top of the pane). The tab will say "Fetching Origin", and then "Refreshing Repository":
    - if your local copy is up to date,  the tab will say "Fetch origin (Last fetched just now)".
    - if changes need to be retrieved from GitHub, the will change to "Pull Origin" (this will also appear as a blue button in the main pane. Select "Pull Origin" in one of these two locations.

3. Click "Current branch (main)", under branches select "New branch" and name it by the following convention:

   `20250502-aqwarning-issue`

4. From GitHub Desktop select "Show in Explorer" to view the repository locally on your computer. In Explorer, navigate to the "\frontend\warnings" subfolder. 

5. Move the Markdown (.md) and map (.html) files from your zip to this folder either by dragging and dropping, or copy pasting. 

6. In GitHub Desktop you should see the files you added show up in the left sidebar under "Changes". Ensure the check-box beside their name is selected. Type a message in the summary box by your profile picture in the bottom of the left side bar, for example:

   `20250502 aq warning issued` 
  
    You don't need to enter anything into the bigger box that is below ("Description")

    Press "Commit 2 files to [branch name]"

7. Select "Publish Branch" in the top right bar.

8. Select “Preview Pull Request”. 
  - A window will pop up showing the two files (.md and .html) - ensure that both (all) the files have been added. 
  - Select “Create Pull Request” in the bottom right of this window. 
  - You may be prompted to re-authenticate your account.
  - It should take a second, but you will be redirected to the [aqwarnings GitHub repository](https://github.com/bcgov/aqwarnings) in your browser and it will say "Open a pull request" at the top of the page. 
  - The commit message you entered in GitHub desktop (above in 6.) will be the PR message (under "Add a title"). You do not have to add a description.
  - Select “Create pull request”.
  
10. Review your changes.
  - You will be redirected to a new page with the commit message at the top (eg. "20250502 aq warning issued #46")
  - You may see a message under your comment in the PR saying “Some checks haven’t completed yet”. When the checks have completed, a new comment will show up “PR Preview Action”. Click to open the link below this to preview the page and Air Quality Warning (e.g. https://bcgov.github.io/aqwarnings/pr-preview/pr-XX/).
  - Review the content at that link, what you are seeing is a complete new copy of the web site with the new warning included. You will have to view the actual warning to make sure the warning message and appearance are what you expected.

11. (Optional) Have another member of your team review and approve changes.
  - A number of Meteorologists will be automatically be assigned to review the issue.
  - If you need to assign another reviewer, from the PR page:
    - Select the gear in the right sidebar, beside "Reviewers"
    - Type the github username of anyone you want to add, when you click out of that menu, you will see their name under reviewers, they will recieve an email.

11. Publish your changes by merging the pull request.
  - Once your change have been reviewed, you are ready to publish your changes.
  - From the PR page. Scroll down below your comment and select "Merge pull request". 
  - The website will automatically be rebuilt with the new warning showing! Give it a few minutes and visit the site: https://aqwarnings.gov.bc.ca to confirm it is live before publishing.
  