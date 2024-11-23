# **ExploreNow**

**ExploreNow** is a travel app designed to help you explore new places with your friends.

---

## **Setup**

Follow these steps to set up the project locally:

### **1. Clone the Repository**
```bash
git clone https://github.com/ShouravRakshit/ExploreNow.git
```
### **2. Navigate to the Project Directory**

```bash
cd ExploreNow
```

### **3. Add API Keys**
Copy the Template:

Duplicate the Secrets.template.plist file to create a new Secrets.plist file.

Update API Keys:

Open Secrets.plist and replace Your_API_Key_Here with your actual API keys.

### **4. Configure Secrets.plist in Xcode**
To properly configure the Secrets.plist file within your Xcode project, follow these detailed steps:

a. Open the Project in Xcode
Start by opening your project in Xcode.

Navigate to the location of your project and double-click on the .xcodeproj or .xcworkspace file to open it.

b. Locate Secrets.plist File
In the Project Navigator on the left side of Xcode, find the Secrets.plist file.

This file is typically located in the main project directory or under a specific group for resources.

c. View the File Inspector
With the Secrets.plist file selected in the Project Navigator, click on the View menu at the top of Xcode.

From the dropdown menu, select Inspectors and then Show File Inspector.


d. Configure Target Membership
In the File Inspector pane, locate the section labeled Target Membership.

You will see a list of project targets with checkboxes next to them.

Ensure that the checkbox for your target (e.g., LBTASwiftUIFirebase) is checked under Any Supported Platform and specifically for iOS.

This ensures that the Secrets.plist file is included in the build when you compile the app for any iOS device.

e. Save Changes
After checking the appropriate boxes in the Target Membership, save your changes in Xcode by pressing Cmd + S.

f. Verify Configuration
Double-check that Secrets.plist is configured correctly by building the project (Cmd + B).

Ensure there are no build errors related to the configuration of this file.

Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

License
This project is licensed under the MIT License.

Contact
For any questions or feedback, please contact Shourav Rakshit.
