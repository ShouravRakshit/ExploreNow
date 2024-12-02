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
### **3. Get API Keys**
Sign up for a free account on [Pixabay](https://pixabay.com/). Once registered, navigate to the [Pixabay API Documentation](https://pixabay.com/api/docs/) to generate your API key. This key will be required for accessing Pixabay's API features.

### **4. Add API Keys**
Copy the Template: Duplicate the Secrets.template.plist file to create a new Secrets.plist file.

Update API Keys: Open Secrets.plist and replace Your_API_Key_Here with your actual API keys.

### **5. Configure Secrets.plist in Xcode**
To properly configure the Secrets.plist file within your Xcode project, follow these detailed steps:

### **6. Open the Project in Xcode**
Start by opening your project in Xcode.

Navigate to the location of your project and double-click on the .xcodeproj or .xcworkspace file to open it.

### **7. Locate Secrets.plist File**
In the Project Navigator on the left side of Xcode, find the Secrets.plist file.

This file is located in the main project directory.

### **8. View the File Inspector**
With the Secrets.plist file selected in the Project Navigator, click on the View menu at the top of Xcode.

From the dropdown menu, select Inspectors and then Show File Inspector.


### **9. Configure Target Membership**
In the File Inspector pane, locate the section labeled Target Membership.

You will see a list of project targets with checkboxes next to them.

Ensure that the checkbox for your target project folder is checked under Any Supported Platform and specifically for iOS.

This ensures that the Secrets.plist file is included in the build when you compile the app for any iOS device.

### **10. Save Changes**
After checking the appropriate boxes in the Target Membership, save your changes in Xcode by pressing Cmd + S.

### **11. Ensure there are no build errors related to the configuration of this file**

### **Contributing**
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

Authors
Shourav Rakshit Ivan,
Alisha Lalani,
Saadman Rahman,
Alina Mansuri,
Manvi Juneja,
Zaid Nissar,
Qusai Dahodwalla, 
Shree Patel,
Vidhi Soni
License
MIT

### **Feedback**
If you have any feedback, please reach out to us at shouravrakshit.ivan@ucalgary.ca
