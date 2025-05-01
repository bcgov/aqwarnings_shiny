# Issue and publish an Air quality warning - Wildfire smoke

Before you begin, you should have access to the team channel with all resources and processes, your username and password for ShinyApps.io and GitHub. Speak to [] for any access and onboarding questions.

## Issue warnings (using ShinyApps.io)

Once you are ready to **issue** an air quality warning here are the steps 

1. Go to the AQ Warnings ShinyApp: https://bcgov-env.shinyapps.io/aqwarnings_shiny/ 
    - Select “Login”
    - Use the username and password you have been provided

2. Complete the fields, following the prompts in the application:
    - Select your name from the author dropdown
    - Confirm or edit the length of time wildfire smoke expected to last
    - Confirm of select the date for next update
    - Add a custom smoke outlook message

3. Select the impacted regions on the map:
    - Hover over regions with your cursor to see their names
    - Click to select a region, once selected the region will be highlighted yellow

4. Select "Go!" to generate the air quality warning:
    - It may take some time to generate, you will see pop-up toasts in the lower right sidebar once it has finished

5. Select "Download Files":
    - A system dialog box will open to ask where you want to save a compressed ZIP archive 
    - Select the location and press "Save"
    - At this stage you may want to open the archive and review the Air Quality Warning PDF to ensure the meteorologist, region, and smoke outlook message are correct

## Publish warnings (via GitHub, Air Quality Subscription Service (AQSS), and Social Media)

Once you have the archive saved you are ready to publish it to [AQ Warnings](https://aqwarnings.gov.bc.ca/) web site and send it to AQSS subscribers and publish to social media.

## Step 1: AQ Warnings web site

[AQ Warnings](https://aqwarnings.gov.bc.ca/) is hosted on GitHub pages. To add warnings you make a Pull Request (PR) on that site, which you can initiate from either:
- GitHub Desktop 
- RStudio
- the git command line interface
- in the browser at https://github.com

We will cover the most popular methods below.

### Using Github Desktop

1. Open GitHub Desktop, ensure the current repository is "aqwarnings"

2. Ensure the Current branch is showing "main" and click "Fetch origin"

3. Click "Current branch", under branches select "New branch", give it a name, for example:

   `20250430-aqwarning-issue `

4. From GitHub Desktop select "Show in Explorer" to view the repository locally on your computer. In Explorer, navigate to the "\frontend\warnings" subfolder. 

5. Move the Markdown (.md) and map (.html) files from your zip to this folder either by dragging and dropping, or copy pasting. 

6. In GitHub Desktop you should see the files you added show up in the left sidebar under "Changes". Ensure the checkbox beside their name is selected. Type a message in the summary box by your profile picture in the bottom of the left side bar, for example:

  `20250430 aq warning issued` 

   Press "Commit to...<branch name>"

7. Select "Publish Branch" in the top right bar.

8. Select “Preview Pull Request”, ensure that both (all) the files are added. Then select “Create Pull Request”
  - The commit message you entered above will be the Pull Request message, you do not have to add a description.

9. Select “Create Pull Request”.
  - You may be prompted to re-authenticate your account
  - It should take a second, but you will be redirected to GitHub.com in your browser

10. Review your changes.
  - You may see a message under the pull request saying “Some checks haven’t completed yet”. When the checks have completed, a comment will show up “PR Preview Action”.

11. When all looks good, go back to the Pull Request on GitHub.
    NOTE: Will you want someone else to review before merging in a change?

#### If you aren't using GitHub Desktop

1. Head to GitHub.com to open a Pull Request (PR): https://github.com/bcgov/aqwarnings/compare
(may be prompted to authenticate)
1. Underneath the title "Compare changes", make sure the base branch is “main” and the compare branch is the one you just created. You should see some files appear, Select the “Create pull request” button.
1. Select “Create Pull Request”
It should take a second, you may see a message under the pull request saying “Some checks haven’t completed yet”


## Step 2: Air Quality Subscription Service 



## Step 3: Post on Social Media 


#### Quick Links

- ShinyApp (authenticated)
    - PROD: https://bcgov-env.shinyapps.io/aqwarnings_shiny/
    - TEST: https://bcgov-env.shinyapps.io/aqwarnings_shiny_test/
- AQ Warnings web site
    - PROD: https://aqwarnings.gov.bc.ca
    - TEST: Each Pull Request (PR) launches a "preview" to test changes before publishing by merging the PR
- GitHub Repo for AQ Warnings (authenticated)
    - https://github.com/bcgov/aqwarnings/