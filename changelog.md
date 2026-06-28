# Changelog

## v15.2

### What's new

* **Optimized GPU Engine**: Completely redesigned how graphics frequencies are mapped and applied, resulting in faster profile switches and better management of game profiles.

### Improvements

* **Reduced Battery & CPU Overhead**: Replaced heavy system command calls with native, lightweight shell functions, resulting in a cleaner execution with less power consumption when checking or changing profiles.
* **Refined Status Interface**: Improved the layout of the device status display and corrected frequency unit reporting so that the dashboard shows exact, readable values.

---

### Notes

* **Configuration Update Recommended**: It is highly recommended to regenerate your device and profile configurations after updating. You can do this by running the following commands in a terminal (with root access):
  * `su -c perfmtk -d` (to regenerate device configurations)
  * `su -c perfmtk -g` (to regenerate default profiles)
