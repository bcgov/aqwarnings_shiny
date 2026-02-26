### Instructions
**Prerequisites**<br>
Ensure you have:<br>
- Access to the **AQ Warnings** Teams channel<br>
- Login credentials for [shinyapps.io](https://login.shinyapps.io/login?redirect=%2Foauth%2Fauthorize%3Fclient_id%3Drstudio-shinyapps%26redirect_uri%3Dhttps%253A%252F%252Fwww.shinyapps.io%252Fauth%252Foauth%252Ftoken%26response_type%3Dcode%26scopes%3D%252A%26show_auth%3D0)<br>
- Access to the **bcgov GitHub** organization<br>

For help, contact Gail Roth, Sakshi Jain, or Donna Haga.
There are also how-to videos on the **AQ Warnings** Teams channel.

**1. Generate the warning (Shiny App)**
<details>
<summary>▶ Steps</summary>

- Log in: [shinyapps.io](https://login.shinyapps.io/login?redirect=%2Foauth%2Fauthorize%3Fclient_id%3Drstudio-shinyapps%26redirect_uri%3Dhttps%253A%252F%252Fwww.shinyapps.io%252Fauth%252Foauth%252Ftoken%26response_type%3Dcode%26scopes%3D%252A%26show_auth%3D0) <br>
- Launch the **aqwarnings_shiny** app
- Select warning type in the sidebar on the left <br>
- Enter warning details <br>
- Generate the warning: Click **Go!** button <br>

<img src="images/1_shinyio_enter_data.png" width="60%" /> <br>

- Wait for the notification box in the bottom right: Processing complete. Files are ready for downloading. <br>

<img src="images/2_shinyio_generate_warning.png" width="80%" /> <br>

- Download the ZIP archive and save to your Downloads folder <br>
- Review the PDF to ensure all details are correct <br>
</details> <br>

**2. Publish the warning on GitHub Pages** <br>
Two options are described here: GitHub.com (recommended) or GitHub Desktop.

<details>
<summary><strong>▶ GitHub.com (recommended)</strong></summary>

1. Open the repository: [https://github.com/bcgov/aqwarnings](https://github.com/bcgov/aqwarnings)

2. Navigate to the [frontend/warnings](https://github.com/bcgov/aqwarnings/tree/main/frontend/warnings) subdirectory in the `main` branch

<img src="images/1_githubcom_open_repo.png" width="80%" /><br>

3. Upload file(s)
- Select **Add file → Upload files**  
- For local-emission warnings or pollution prevention notices, drag the `.md` file(s) from the ZIP archive. <br>
- For wildfire smoke warnings, drag the `.md` file and the `.html` file from the ZIP archive. <br>

<img src="images/2a_githubcom_upload_files.png" width="80%" /> <br>
<img src="images/2b_githubcom_upload_files.png" width="80%" /> <br>

4. Propose changes
- Use this naming convention for the commit message and branch name: `YYYYMMDD-aqwarning-issue`
- Click **Propose changes**.<br>
<img src="images/3_githubcom_propose_changes.png" width="80%" /> <br>

5. Create Pull Request
- Confirm the Pull Request will merge into the **main** branch
- Click **Create pull request**. <br>

<img src="images/4_githubcom_create_pull_request.png" width="80%" /> <br>

6. Review Automated Checks
- Wait for the **PR Preview Action** comment
- Open the preview
- Verify the warning appears correctly
- Use back button to return to the Pull Request page <br>

<img src="images/5_githubcom_preview.png" width="60%" /><br>

7. (Optional) Request Review <br>
To bypass a review:
- Select: Merge without waiting for requirements
- Click **Bypass rules and merge** <br>

<img src="images/6_githubcom_review_and_merge.png" width="60%" />

8. Publish
- Merge the Pull Request and wait a few minutes. 
- Confirm the warning appears at [https://aqwarnings.gov.bc.ca](https://aqwarnings.gov.bc.ca)
</details>
<details>
<summary><strong>▶ GitHub Desktop</strong></summary>

1. Open the aqwarnings Repository
- Open **GitHub Desktop** <br>
- Select or clone `bcgov/aqwarnings` <br>  
- Ensure branch = **main** <br>
- Click **Fetch origin** <br>

<img src="images/1_githubdesktop_open_repo.png" width="80%" /> <br>

2. Create a new branch
- Click **Current branch (main)** <br>
- Under branches select **New branch**. <br> 
- Branch naming format: `YYYYMMDD-aqwarning-issue` <br>

<img src="images/2_githubdesktop_new_branch.png" width="80%" /> <br>

3. Navigate to the warnings folder
- Select **Show in Explorer** <br>
- In Windows Explorer, navigate to the `\frontend\warnings` subfolder. <br>

<img src="images/3_githubdesktop_warnings_folder.png" width="80%" /> <br>

4. Move files to GitHub repository
- For local-emission warnings or pollution prevention notices, drag the `.md` file(s) from the ZIP archive to the `\frontend\warnings` subdirectory <br>
- For wildfire smoke warnings, drag the `.md` file and `.html` file from the ZIP archive to the `\frontend\warnings` subdirectory <br>

<img src="images/4_githubdesktop_move_files.png" width="80%" /> <br>

5. Commit changes
- In GitHub Desktop view changes in left sidebar. <br>
- Ensure check-box beside each file is selected. <br> 
- Add a title to the summary box (bottom of the left side bar) with the following format:`YYYYMMDD-aqwarning-issue` <br>
- (Optional) add a description <br>
- Click **Commit** button <br>

<img src="images/5_githubdesktop_commit.png" width="60%" /> <br>

6. Publish branch

<img src="images/6_githubdesktop_publish.png" width="60%" /> <br>

7. Preview pull request
- Click **Preview Pull Request** <br>
- A window will pop up showing files to be committed <br>
- Verify all intended files are included, then click **Create Pull Request**. <br>

<img src="images/7_githubdesktop_create_pull_request.png" width="60%" /> <br>

8. Open Pull Request
- You will be redirected to the Pull Request in the [aqwarnings GitHub repository](https://github.com/bcgov/aqwarnings) on Github.com <br>
- Confirm that the Pull Request target is the `main` branch (see highlighted text in screenshot) <br>
- Click **Create pull request**. <br>

<img src="images/4_githubcom_create_pull_request.png" width="80%" /> <br>

9. Review automated checks
- Wait for the Pull Request Preview Action comment <br>
- Open the preview link <br>
- Navigate through the preview site to verify the warning appears correctly <br>

<img src="images/5_githubcom_preview.png" width="80%" /> <br>

10. (Optional) Request a review
- To bypass a review <br>
    - check "Merge without waiting for requirements to be met (bypass rules)" <br>
    - click on **Bypass rules and merge button**<br>
    
<img src="images/6_githubcom_review_and_merge.png" width="80%" /> <br>

11. Publish
- Click **Confirm Merge pull request** <br>
- Wait a few minutes <br>
- Confirm the the warning appears on [https://aqwarnings.gov.bc.ca](https://aqwarnings.gov.bc.ca)
</details> <br>

**3. Notify Subscribers** <br>
Once the warning is live, send Air Quality Subscription (AQSS) notifications using the standard process (see AQ Warnings Teams channel for instructions).

**4. File the PDF in ORCS and update summary stats** <br>
In the ORCS directory **26600-04 Reporting - Air Quality Warnings**: <br>
- Save PDF(s) from the ZIP archive <br>
- Update summary file: **summary_warnings_local_emissions.xlsx** <br>

