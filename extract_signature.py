#!/usr/bin/env python3

import sys
import zipfile
import tempfile
import os
import binascii
import base64

def extract_android_signature(apk_path):
    """
    从 APK 文件中提取签名信息，模拟 Android 的 Signature.toCharsString() 行为
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
            
            # 读取证书文件的二进制内容
            with open(extracted_path, 'rb') as cert_file:
                cert_data = cert_file.read()
            
            # 模拟 Android 的 Signature.toCharsString() 行为
            # 在 Android 中，Signature.toCharsString() 返回的是 Base64 编码的证书数据
            # 但格式化为带有 BEGIN/END 标记的多行字符串
            
            # 首先进行 Base64 编码
            base64_cert = base64.b64encode(cert_data).decode('utf-8')
            
            # 格式化为多行（每行 64 字符）
            formatted_cert = "-----BEGIN CERTIFICATE-----\n"
            for i in range(0, len(base64_cert), 64):
                formatted_cert += base64_cert[i:i+64] + "\n"
            formatted_cert += "-----END CERTIFICATE-----"
            
            return formatted_cert

def main():
    if len(sys.argv) != 2:
        print("Usage: python extract_signature.py <apk_file>")
        sys.exit(1)
        
    apk_path = sys.argv[1]
    if not os.path.isfile(apk_path):
        print(f"Error: APK file not found: {apk_path}")
        sys.exit(1)
        
    signature_string = extract_android_signature(apk_path)
    if signature_string:
        print(signature_string)
    else:
        print("Error: Failed to extract signature")
        sys.exit(1)

if __name__ == "__main__":
    main()
