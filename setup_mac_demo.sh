#!/bin/bash

# 设置错误时退出
set -e

echo "Starting setup for macOS demo..."

# 1. 定义路径
PROJECT_ROOT=$(pwd)
BUILD_DIR="${PROJECT_ROOT}/build/build_x64/bin"
DIST_DIR="${PROJECT_ROOT}/dist"
DEMO_DIR="${PROJECT_ROOT}/demo_mac"

# 2. 创建目录结构
echo "Creating directory structure..."
rm -rf "${DEMO_DIR}"
mkdir -p "${DEMO_DIR}"
mkdir -p "${DEMO_DIR}/common"
mkdir -p "${DEMO_DIR}/cta"
mkdir -p "${DEMO_DIR}/hft"
mkdir -p "${DEMO_DIR}/sel"
mkdir -p "${DEMO_DIR}/parsers"
mkdir -p "${DEMO_DIR}/traders"
mkdir -p "${DEMO_DIR}/executers"
mkdir -p "${DEMO_DIR}/strategies"

# 3. 复制可执行文件和库
echo "Copying executables and libraries..."
cp "${BUILD_DIR}/WtRunner/WtRunner" "${DEMO_DIR}/"
# 复制所有生成的dylib到根目录或对应子目录
# WtRunner 会在 parsers/traders 等目录下查找插件
# 从 WtRunner 子目录复制，因为构建过程已经归档好了
cp "${BUILD_DIR}/WtRunner/parsers/"*.dylib "${DEMO_DIR}/parsers/" 2>/dev/null || true
cp "${BUILD_DIR}/WtRunner/traders/"*.dylib "${DEMO_DIR}/traders/" 2>/dev/null || true
cp "${BUILD_DIR}/WtRunner/executer/"*.dylib "${DEMO_DIR}/executers/" 2>/dev/null || true

# WtCtaStraFact (策略工厂) 通常也是动态库
if [ -f "${BUILD_DIR}/libWtCtaStraFact.dylib" ]; then
    cp "${BUILD_DIR}/libWtCtaStraFact.dylib" "${DEMO_DIR}/cta/"
    cp "${BUILD_DIR}/libWtCtaStraFact.dylib" "${DEMO_DIR}/"
fi

# 确保所有脚本和可执行文件有执行权限
chmod +x "${DEMO_DIR}/WtRunner"

# 复制核心依赖库 (如果有的话，通常在 bin 根目录)
cp "${BUILD_DIR}/WtRunner/"*.dylib "${DEMO_DIR}/" 2>/dev/null || true

# 4. 复制配置和数据
echo "Copying configuration and data..."
# 复制 common 数据
cp -r "${DIST_DIR}/common/"* "${DEMO_DIR}/common/"

# 复制 WtRunnerCta 的配置作为模板
cp "${DIST_DIR}/WtRunnerCta/"*.yaml "${DEMO_DIR}/"

# 5. 修改配置文件适配 macOS
echo "Patching configuration files..."

# 5.1 修改 config.yaml
# 将 windows 路径分隔符转换 (如果有)
# 这里主要是修改引用路径，因为我们将 common 放到了 demo_mac/common
# 原配置: ../common/xxx
# 新结构: common/xxx
# 所以只需要去掉 ../
sed -i '' 's|\.\./common/|common/|g' "${DEMO_DIR}/config.yaml"

# 5.2 修改 tdparsers.yaml
# 将 .dll 替换为 .dylib，并添加 lib 前缀 (如果需要)
# ParserUDP.dll -> libParserUDP.dylib
sed -i '' 's/ParserUDP.dll/libParserUDP.dylib/g' "${DEMO_DIR}/tdparsers.yaml"
sed -i '' 's/ParserCTP.dll/libParserCTP.dylib/g' "${DEMO_DIR}/tdparsers.yaml"

# 5.3 修改 tdtraders.yaml
# 替换 .dll 为 .dylib
sed -i '' 's/\.dll/.dylib/g' "${DEMO_DIR}/tdtraders.yaml"
# 给模块名加上 lib 前缀 (例如 TraderCTP -> libTraderCTP)
# 注意：配置中的 module 字段通常是 "TraderCTP"，DLLHelper会自动添加前缀后缀
# 但是如果我们之前的修改生效了，我们需要确认配置怎么写。
# 如果配置写 module: TraderCTP，DLLHelper::wrap_module 会变成 libTraderCTP.dylib
# 所以不需要在配置文件里改 module 名，只需要改 path 引用或者确保文件存在。
# 但是 tdtraders.yaml 中可能没有直接写文件名，而是写 module 名。
# 让我们检查一下 yaml 内容。
# 如果是 module: TraderCTP，则不需要修改，只需要文件名为 libTraderCTP.dylib。

# 5.4 修改 executers.yaml
sed -i '' 's/\.dll/.dylib/g' "${DEMO_DIR}/executers.yaml"

# 5.5 修改策略配置 config.yaml 中的 strategies 部分
sed -i '' 's/WtCtaStraFact.dll/libWtCtaStraFact.dylib/g' "${DEMO_DIR}/config.yaml"

# 6. 特殊处理：禁用不可用的模块 (如 CTP Trader)
# 因为 macOS 没有 CTP 库，我们改用 TraderMocker 或注释掉
echo "Disabling CTP Trader and enabling TraderMocker..."

# 创建一个新的 tdtraders.yaml 使用 TraderMocker
cat > "${DEMO_DIR}/tdtraders.yaml" <<EOF
traders:
-   active: true
    id: mocker
    module: TraderMocker
    savedata: true
EOF

# 修改 config.yaml 中的 traders 引用 (不需要改，因为还是 tdtraders.yaml)

# 7. 确保数据目录存在
mkdir -p "${DEMO_DIR}/FUT_Data"

echo "Setup complete!"
echo "To run the demo:"
echo "  cd ${DEMO_DIR}"
echo "  ./WtRunner"
