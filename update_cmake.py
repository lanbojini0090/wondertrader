import os

def process_cmake_files(root_dir):
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename == "CMakeLists.txt":
                filepath = os.path.join(dirpath, filename)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                new_content = content
                
                # Case 1: IF(WIN32) ... LIST(APPEND LIBS iconv) ... ENDIF()
                if "LIST(APPEND LIBS iconv)" in content and "ws2_32" not in content:
                    new_content = new_content.replace("IF(WIN32)", "IF(WIN32 OR APPLE)")
                    new_content = new_content.replace("if(WIN32)", "if(WIN32 OR APPLE)")

                # Case 2: ws2_32 iconv
                elif "ws2_32 iconv" in content:
                    # Find the IF(WIN32) block containing ws2_32 iconv
                    lines = content.split('\n')
                    new_lines = []
                    skip = False
                    for i, line in enumerate(lines):
                        new_lines.append(line)
                        if "ws2_32 iconv" in line:
                             # check if we are inside IF(WIN32)
                             pass 
                    
                    # Easier approach: replace IF(WIN32) with IF(WIN32) ... ELSEIF(APPLE) ...
                    # But since the structure varies, let's use a simpler replacement for now.
                    # We can replace "ws2_32 iconv)" with "ws2_32 iconv)\n\tELSEIF(APPLE)\n\t\tLIST(APPEND LIBS iconv)"
                    # But this depends on context.
                    
                    # Let's try to find the closing ENDIF() for the WIN32 block.
                    # This is risky with simple replace.
                    pass

                if new_content != content:
                    with open(filepath, 'w') as f:
                        f.write(new_content)
                    print(f"Updated {filepath}")

# Execute
process_cmake_files("src")
