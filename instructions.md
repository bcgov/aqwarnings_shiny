# Issue and publish an Air Quality Warning - Wildfire smoke

Before you begin, you should have access to the [Wildfire channel](https://teams.microsoft.com/l/channel/19%3Adbcd68403ff248a5b85d86b3c0f2edfb%40thread.tacv2/Wildfire?groupId=08b39b07-19dc-4340-9e31-ecea7c416570&tenantId=6fdb5200-3d0d-4a8a-b036-d3685e359adc) in Microsoft Teams, your username and password for [ShinyApps.io](login.shinyapps.io) and [GitHub](github.com). Speak to Gail Roth, Sakshi Jain, or Donna Haga for any access and onboarding questions.

## Issue warnings (using ShinyApps.io)

Once you are ready to **issue** an air quality warning here are the steps: 

1. Go to the AQ Warnings ShinyApp: https://bcgov-env.shinyapps.io/aqwarnings_shiny/ 
    - Select “Login”
    - Use the username and password you have been provided.
    - The ShinyApp should open

2. Complete the fields, following the prompts in the application:
    - Select your name from the author drop-down
    - Confirm or edit the length of time wildfire smoke expected to last
    - Confirm or select the date for next update
    - Add a custom smoke outlook message (optional)

3. Select the impacted regions on the map:
    - Hover over regions with your cursor to see their names
    - Click to select/de-select a region, once selected the region will be highlighted yellow. If needed, you can de-select all the regions on the map using the "Reset Map" button above the map.
    - Several layers can be overlaid on the map using the check-boxes in the legend in the upper right corner of the map window. These layers can be useful when informing your decision (for example, to see extent of smoke impact) 

4. Select or create a description summarizing what areas of the province will be included in the Warning. Under "Describe regions affected", you can either:
    - select from pre-packaged descriptions using the drop down menu, or
    - type in a custom description in the field.

5. Select "Go!" to generate the Air Quality Warning:
    - It may take some time to generate, you will see pop-up toasts in the lower right sidebar once it has finished. You are looking for these messages: "PDF generation complete!" and "Markdown generation complete!".

6. Select "Download Files":
    - A system dialog box may open to ask where you want to save a compressed ZIP archive->Select the location and press "Save".
    - In Chrome, the ZIP archive will automatically get saved to your "Downloads" folder. 
    - At this stage you may want to open the archive and review the Air Quality Warning PDF to ensure the meteorologist, region, and smoke outlook message are correct
    
7. [DO WE STILL NEED THIS STEP?] Select "clean dir" to delete auxillary files in the working directory.
    

## Publish warnings (via GitHub, Air Quality Subscription Service (AQSS), and Social Media)

Once you have the archive saved you are ready to publish it to [AQ Warnings](https://aqwarnings.gov.bc.ca/) web site, send it to AQSS subscribers, and publish to social media.

## Step 1: AQ Warnings web site

[AQ Warnings](https://aqwarnings.gov.bc.ca/) is hosted on GitHub pages. To add warnings you make a Pull Request (PR) on that site, which you can initiate from either:
- GitHub Desktop 
- RStudio
- the git command line interface
- in the browser at https://github.com

We will cover the method using GitHub desktop below.

### Using Github Desktop

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
  

## Step 2: Air Quality Subscription Service and on Social Media

This process has not changed from last year.

#### Quick Links

- AQ Warnings ShinyApp (authenticated)
    - PROD: https://bcgov-env.shinyapps.io/aqwarnings_shiny/
    - TEST: https://bcgov-env.shinyapps.io/aqwarnings_shiny_test/ 
- AQ Warnings web site
    - PROD: https://aqwarnings.gov.bc.ca
    - TEST: Each Pull Request (PR) launches a "preview" to test changes before publishing by merging the PR
- GitHub Repo for AQ Warnings (authenticated)
    - https://github.com/bcgov/aqwarnings/