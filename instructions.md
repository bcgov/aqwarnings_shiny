# Issue and publish an Air Quality Warning - Wildfire smoke

Before you begin, you should have access to the Microsoft Teams channel [INSERT LINK] with all resources and processes, your username and password for ShinyApps.io and GitHub. Speak to Gail Roth, Sakshi Jain, or Donna Haga for any access and onboarding questions.

## Issue warnings (using ShinyApps.io)

Once you are ready to **issue** an air quality warning here are the steps: 

1. Go to the AQ Warnings ShinyApp: https://bcgov-env.shinyapps.io/aqwarnings_shiny/ 
    - Select “Login”
    - Use the username and password you have been provided

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

2. Ensure the Current branch is showing "main" and click "Fetch origin".

3. Click "Current branch (main)", under branches select "New branch" and name it by the following convention:

   `20250502-aqwarning-issue`

4. From GitHub Desktop select "Show in Explorer" to view the repository locally on your computer. In Explorer, navigate to the "\frontend\warnings" subfolder. 

5. Move the Markdown (.md) and map (.html) files from your zip to this folder either by dragging and dropping, or copy pasting. 

6. In GitHub Desktop you should see the files you added show up in the left sidebar under "Changes". Ensure the check-box beside their name is selected. Type a message in the summary box by your profile picture in the bottom of the left side bar, for example:

  `20250502 aq warning issued` 
  
   You don't need to enter anything into the bigger box that is below ("Description")

   Press "Commit 2 files to <branch name>"

7. Select "Publish Branch" in the top right bar.

8. Select “Preview Pull Request”. 
  - A window will pop up showing the two files (.md and .html) - ensure that both (all) the files have been added. 
  - Select “Create Pull Request” in the bottom right of this window. 
  - You may be prompted to re-authenticate your account.
  - It should take a second, but you will be redirected to the [aqwarnings GitHub repository](https://github.com/bcgov/aqwarnings) in your browser that says "Open a pull request" at the top of the page. 
  - The commit message you entered in GitHub desktop (above in 6.) will be the Pull Request message (under "Add a title"). You do not have to add a description.
  - Select “Create pull request”.
  

10. Review your changes.
  - You will be redirected to a new page with the commit message at the top (eg. "20250502 aq warning issued #46")
  - You may see a message under the pull request saying “Some checks haven’t completed yet”. When the checks have completed, a comment will show up “PR Preview Action” -> open the link below this (e.g. https://bcgov.github.io/aqwarnings/pr-preview/pr-46/) in a new tab to preview the page and Air Quality Warning.

11. If all looks good, go back to the Pull Request on GitHub.
    NOTE: Will you want someone else to review before merging in a change?
    [NEED TO ADD FINAL STEPS - MERGING INTO MAIN, DELETING BRANCH]

## Step 2: Air Quality Subscription Service 
[TO BE ADDED LATER]


## Step 3: Post on Social Media 
[TO BE ADDED LATER]

#### Quick Links

- ShinyApp (authenticated)
    - PROD: https://bcgov-env.shinyapps.io/aqwarnings_shiny/
    - TEST: https://bcgov-env.shinyapps.io/aqwarnings_shiny_test/
- AQ Warnings web site
    - PROD: https://aqwarnings.gov.bc.ca
    - TEST: Each Pull Request (PR) launches a "preview" to test changes before publishing by merging the PR
- GitHub Repo for AQ Warnings (authenticated)
    - https://github.com/bcgov/aqwarnings/