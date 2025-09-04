#!/usr/bin/env python3

import sys
import zipfile
import subprocess
import tempfile
import os
import re

def extract_signature(apk_path):
    """
    从 APK 文件中提取签名信息
    """
    # 创建临时目录
    with tempfile.TemporaryDirectory() as temp_dir:
        # 解压 META-INF 目录
        with zipfile.ZipFile(apk_path, 'r') as apk_zip:
            # 查找签名文件
            signature_files = [f for f in apk_zip.namelist() 
                             if f.startswith('META-INF/') and 
                             (f.endswith('.RSA') or f.endswith('.DSA') or f.endswith('.EC'))]
            
            if not signature_files:
                print("Error: No signature files found in APK")
                return None
                
            # 提取第一个签名文件
            signature_file = signature_files[0]
            extracted_path = os.path.join(temp_dir, os.path.basename(signature_file))
            apk_zip.extract(signature_file, temp_dir)
            
            # 移动文件到正确位置
            os.rename(os.path.join(temp_dir, signature_file), extracted_path)
            
            # 使用 keytool 提取签名信息
            try:
                result = subprocess.run([
                    'keytool', '-printcert', '-file', extracted_path
                ], capture_output=True, text=True, check=True)
                
                # 提取 SHA1 和 SHA256 指纹
                output = result.stdout
                sha1_match = re.search(r'SHA1:\s*([0-9A-F:]+)', output)
                sha256_match = re.search(r'SHA256:\s*([0-9A-F:]+)', output)
                
                if sha1_match:
                    sha1 = sha1_match.group(1).replace(':', '').lower()
                else:
                    sha1 = None
                    
                if sha256_match:
                    sha256 = sha256_match.group(1).replace(':', '').lower()
                else:
                    sha256 = None
                    
                return {
                    'sha1': sha1,
                    'sha256': sha256,
                    'raw_output': output
                }
                
            except subprocess.CalledProcessError as e:
                print(f"Error running keytool: {e}")
                return None
            except FileNotFoundError:
                print("Error: keytool not found. Make sure Java JDK is installed.")
                return None

def main():
    if len(sys.argv) != 2:
        print("Usage: python extract_signature.py <apk_file>")
        sys.exit(1)
        
    apk_path = sys.argv[1]
    if not os.path.isfile(apk_path):
        print(f"Error: APK file not found: {apk_path}")
        sys.exit(1)
        
    signature_info = extract_signature(apk_path)
    if signature_info:
        # 输出 SHA1 签名 (与原始Java代码最接近的匹配)
        if signature_info['sha1']:
            print(signature_info['sha1'])
        else:
            print("Error: Could not extract signature")
            sys.exit(1)
    else:
        print("Error: Failed to extract signature")
        sys.exit(1)

if __name__ == "__main__":
    main()
