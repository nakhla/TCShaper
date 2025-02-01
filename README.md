# **TCShaper: A Wondershaper-Inspired Traffic Shaping Utility with IFB Support**

**TCShaper** is a lightweight shell script for bandwidth shaping on Linux, inspired by **Wondershaper** but enhanced with **IFB (Intermediate Functional Block) support** for more accurate download speed control.

## **Features**

✅ **Accurate Download & Upload Limits** using `tc` and `ifb0`  
✅ **Overhead Compensation** for better speed consistency  
✅ **Automatic IFB Setup & Cleanup**  
✅ **Simple Commands for Easy Usage**  

## **Installation**

1. Download the script:  
   ```bash
   wget https://github.com/nakhla/tcshaper.sh -O /usr/local/bin/tcshaper
   chmod +x /usr/local/bin/tcshaper
   ```  

2. Ensure the IFB module is available:  
   ```bash
   sudo modprobe ifb
   ```  

## **Usage**

### **Set Bandwidth Limits**

Limit download to **8 Mbps** and upload to **2 Mbps** on `eth0`:  
```bash
 tcshaper eth0 8192 2048
```

### **Clear Bandwidth Limits**

Remove all traffic shaping rules and restore full speed:  
```bash
 tcshaper eth0 clear
```

## **How It Works**

- Uses **HTB (Hierarchical Token Bucket)** for precise rate limiting.  
- Redirects incoming traffic through an **IFB device** for proper download shaping.  
- Compensates for network overhead to improve shaping accuracy.  

---


