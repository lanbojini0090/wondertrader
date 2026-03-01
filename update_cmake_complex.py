import os

def process_complex_files(root_dir):
    files = [
        "src/QuoteFactory/CMakeLists.txt",
        "src/TraderDumper/CMakeLists.txt",
        "src/WtDtPorter/CMakeLists.txt",
        "src/WtLatencyHFT/CMakeLists.txt",
        "src/WtLatencyUFT/CMakeLists.txt",
        "src/WtPorter/CMakeLists.txt",
        "src/WtRunner/CMakeLists.txt",
        "src/WtUftRunner/CMakeLists.txt"
    ]
    
    for filepath in files:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Pattern 1: LIST(APPEND LIBS ws2_32 iconv)
            if "LIST(APPEND LIBS ws2_32 iconv)" in content:
                content = content.replace("LIST(APPEND LIBS ws2_32 iconv)", "LIST(APPEND LIBS ws2_32 iconv)\n\tELSEIF(APPLE)\n\t\tLIST(APPEND LIBS iconv)")
            
            # Pattern 2: Multi-line
            # LIST(APPEND LIBS
            # 	ws2_32 iconv)
            if "ws2_32 iconv)" in content:
                 content = content.replace("ws2_32 iconv)", "ws2_32 iconv)\n\tELSEIF(APPLE)\n\t\tLIST(APPEND LIBS iconv)")

            with open(filepath, 'w') as f:
                f.write(content)
            print(f"Updated {filepath}")

process_complex_files(".")
