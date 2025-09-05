#!/usr/bin/env python3

import sys
import zipfile
import tempfile
import os
import binascii
import base64
import json

def extract_certificate_info(apk_path):
    """
    从 APK 文件中提取证书信息，返回包含多种格式的字典
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
            
            # 转换为十六进制字符串
            hex_cert = binascii.hexlify(cert_data).decode('utf-8')
            
            # 转换为 Base64 字符串（带格式）
            base64_cert = base64.b64encode(cert_data).decode('utf-8')
            formatted_cert = "-----BEGIN CERTIFICATE-----\n"
            for i in range(0, len(base64_cert), 64):
                formatted_cert += base64_cert[i:i+64] + "\n"
            formatted_cert += "-----END CERTIFICATE-----"
            
            return {
                'hex': hex_cert,
                'base64': formatted_cert,
                'signature_file': signature_file
            }

def main():
    if len(sys.argv) != 2:
        print("Usage: python extract_signature.py <apk_file>")
        sys.exit(1)
        
    apk_path = sys.argv[1]
    if not os.path.isfile(apk_path):
        print(f"Error: APK file not found: {apk_path}")
        sys.exit(1)
        
    certificate_info = extract_certificate_info(apk_path)
    if certificate_info:
        # 输出十六进制格式（与 Android Signature.toByteArray() 匹配）
        print(certificate_info['hex'])
    else:
        print("Error: Failed to extract certificate data")
        sys.exit(1)

if __name__ == "__main__":
    main()
