#!/system/bin/sh
# nan独家工具v1.0.14
# 适配iQOO Z8/MT管理器 | 恢复操作提示符+完整功能

# 强制设置终端环境，避免输出异常
export TERM=xterm-256color
set +x  # 关闭命令回显

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# 代码高亮
CODE_KEY='\033[1;35m'   # 关键字紫
CODE_SYM='\033[1;33m'   # 符号黄
CODE_TXT='\033[1;37m'   # 文本白
CODE_COMM='\033[1;32m'  # 注释绿
CODE_BG='\033[40m'      # 背景黑

# 细边框UI
BOX_TOP="┌──────────────────────────────────────────────────────────┐"
BOX_MID="├──────────────────────────────────────────────────────────┤"
BOX_BOT="└──────────────────────────────────────────────────────────┘"
BOX_SUB="├──────────────────────────────────────────────────────────┤"
LINE="──────────────────────────────────────────────────────────"
COL_PAD="                                        "

# 图标
FOLDER_ICON="📁"
FILE_ICON="📄"
CODE_ICON="💻"
APK_ICON="📱"
ZIP_ICON="🗜️"
ARROW="▶"
CHECK="✅"
ERROR="❌"

# ==================== 核心工具函数 ====================
# 1. 原生强制清屏（移除tput依赖，适配Android）
force_clear() {
    clear
    printf "\033[H\033[2J"  # 光标归位+清屏
    printf "\033[3J"        # 清除滚动缓冲区
}

# 2. 获取文件/文件夹大小
get_size() {
    local path="$1"
    if [ -d "$path" ]; then
        du -sh "$path" 2>/dev/null | awk '{print $1}' || echo "未知"
    elif [ -f "$path" ]; then
        local size=$(ls -l "$path" 2>/dev/null | awk '{print $5}')
        [ -z "$size" ] && size=0
        if [ $size -ge 1048576 ]; then
            echo "$(echo "scale=2; $size/1048576" | bc)MB"
        elif [ $size -ge 1024 ]; then
            echo "$(echo "scale=2; $size/1024" | bc)KB"
        else
            echo "${size}B"
        fi
    else
        echo "未知"
    fi
}

# 3. 字符串长度计算
str_len() {
    local str="$1"
    echo -n "$str" | wc -m 2>/dev/null || echo 0
}

# 4. 列对齐
align_col() {
    local content="$1"
    local target_len="$2"
    local curr_len=$(str_len "$content")
    local pad_len=$((target_len - curr_len))
    [ $pad_len -gt 0 ] && echo -n "$content$(printf "%0.s " $(seq 1 $pad_len))" || echo -n "$content"
}

# 5. 文件类型判断
get_file_icon() {
    local ext="${1##*.}"
    case "$ext" in
        sh|py|java|c|cpp|h|xml|json|yml|yaml|html|css|js|txt) echo "$CODE_ICON" ;;
        apk) echo "$APK_ICON" ;;
        zip|rar|7z) echo "$ZIP_ICON" ;;
        *) echo "$FILE_ICON" ;;
    esac
}

# 6. 打开文件处理（强制显示代码）
open_file_handler() {
    local file="$1"
    local ext="${1##*.}"
    force_clear  # 原生清屏

    # 拼接完整路径
    local full_path
    if [ -f "$file" ]; then
        full_path="$file"
    elif [ -f "$(pwd)/$file" ]; then
        full_path="$(pwd)/$file"
    else
        full_path="$file"
    fi

    echo -e "${CODE_BG}${CYAN}${BOX_TOP}${RESET}"
    case "$ext" in
        apk)
            echo -e "${CODE_BG}${CYAN}│${MAGENTA}      📱 APK文件操作 - $(basename "$file")      ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
            echo -e "${CODE_BG}${CYAN}│${YELLOW}  提示：请在MT管理器中打开此文件进行安装          ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}│${BLUE}  文件路径：$full_path                          ${CYAN}│${RESET}"
            ;;
        zip|rar|7z)
            echo -e "${CODE_BG}${CYAN}│${MAGENTA}      🗜️  压缩包文件 - $(basename "$file")      ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
            echo -e "${CODE_BG}${CYAN}│${YELLOW}  提示：请在MT管理器中打开此文件进行解压          ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}│${BLUE}  文件路径：$full_path                          ${CYAN}│${RESET}"
            ;;
        # 代码文件显示所有内容
        sh|py|java|c|cpp|h|xml|json|yml|yaml|html|css|js|txt)
            echo -e "${CODE_BG}${CYAN}│${MAGENTA}      💻 代码文件 - $(basename "$file")      ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
            if [ -r "$full_path" ]; then
                while IFS= read -r line; do
                    # 注释高亮
                    colored_line=$(echo "$line" | sed -e "s/^#.*/${CODE_COMM}&${CODE_TXT}/g" \
                                                     -e "s/^\/\/.*/${CODE_COMM}&${CODE_TXT}/g" \
                                                     -e "s/\/\*.*\*\//${CODE_COMM}&${CODE_TXT}/g")
                    # 关键字高亮
                    colored_line=$(echo "$colored_line" | sed -e "s/\<if\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<else\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<for\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<while\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<function\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<return\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<def\>/${CODE_KEY}&${CODE_TXT}/g" \
                                                     -e "s/\<class\>/${CODE_KEY}&${CODE_TXT}/g")
                    # 符号高亮
                    colored_line=$(echo "$colored_line" | sed -e "s/[{}()=+\\-*\/;:,[\]]/${CODE_SYM}&${CODE_TXT}/g")
                    
                    if [ $(str_len "$colored_line") -gt 55 ]; then
                        echo -e "${CODE_BG}${CYAN}│ ${CODE_TXT}${colored_line:0:55}...${RESET}${CYAN} │${RESET}"
                    else
                        echo -e "${CODE_BG}${CYAN}│ ${CODE_TXT}${colored_line}${RESET}${CYAN} │${RESET}"
                    fi
                done < "$full_path" 2>/dev/null
            else
                echo -e "${CODE_BG}${CYAN}│${RED}  无法读取文件：权限不足或文件不存在  ${CYAN}│${RESET}"
            fi
            ;;
        # 普通文件显示内容
        *)
            echo -e "${CODE_BG}${CYAN}│${MAGENTA}      📄 文本文件 - $(basename "$file")      ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
            if [ -r "$full_path" ]; then
                while IFS= read -r line; do
                    [ $(str_len "$line") -gt 55 ] && line="${line:0:55}..."
                    echo -e "${CODE_BG}${CYAN}│ ${WHITE}$line${CYAN} │${RESET}"
                done < "$full_path" 2>/dev/null
            else
                echo -e "${CODE_BG}${CYAN}│${RED}  无法读取文件内容                              ${CYAN}│${RESET}"
            fi
            ;;
    esac
    echo -e "${CODE_BG}${CYAN}${BOX_BOT}${RESET}"
    echo -e "${GREEN}按回车键返回文件管理器...${RESET}"
    read -r
}

# ==================== 主函数（恢复所有操作提示） ====================
main() {
    # 初始目录强制/sdcard
    CURRENT_DIR="/sdcard"
    [ ! -d "$CURRENT_DIR" ] && CURRENT_DIR="$(pwd)"
    cd "$CURRENT_DIR" 2>/dev/null || CURRENT_DIR="$(pwd)"

    while true; do
        force_clear
        CURRENT_DIR="$(pwd)"
        
        # 绘制主界面+恢复完整操作提示
        echo -e "${CODE_BG}${CYAN}${BOX_TOP}${RESET}"
        echo -e "${CODE_BG}${CYAN}│${MAGENTA}      nan独家_文件管理工具1.0.14      ${CYAN}│${RESET}"
        echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
        
        # 显示当前目录
        current_path_display="$CURRENT_DIR"
        [ $(str_len "$current_path_display") -gt 55 ] && current_path_display="...${current_path_display: -52}"
        echo -e "${CODE_BG}${CYAN}│${GREEN} 当前目录: ${YELLOW}$current_path_display${CYAN}│${RESET}"
        echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"

        # 初始化数组
        unset dir_names dir_paths file_names file_paths file_icons
        dir_count=0
        declare -a dir_names dir_paths
        file_count=0
        declare -a file_names file_paths file_icons

        # 遍历文件/文件夹
        for item in *; do
            [ "$item" = "." ] || [ "$item" = ".." ] && continue
            if [ -d "$item" ] && [ -r "$item" ]; then
                dir_names[$dir_count]="$item"
                dir_paths[$dir_count]="$item"
                ((dir_count++))
            elif [ -f "$item" ] && [ -r "$item" ]; then
                file_names[$file_count]="$item"
                file_paths[$file_count]="$item"
                file_icons[$file_count]=$(get_file_icon "$item")
                ((file_count++))
            fi
        done 2>/dev/null

        # 显示文件夹列表
        if [ $dir_count -gt 0 ]; then
            echo -e "${CODE_BG}${CYAN}│${BLUE}      📁 文件夹列表 ($dir_count 个)      ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
            for ((i=0; i<dir_count; i++)); do
                [ $i -ge ${#dir_names[@]} ] && break
                index=$((i + 1))
                dir_name="${dir_names[$i]}"
                dir_size=$(get_size "${dir_paths[$i]}")
                aligned_name=$(align_col "$dir_name" 30)
                echo -e "${CODE_BG}${CYAN}│${WHITE} [${GREEN}$index${WHITE}]${ARROW} ${FOLDER_ICON} ${YELLOW}${aligned_name}${BLUE} [$dir_size] ${CYAN}│${RESET}"
                [ $i -lt $((dir_count - 1)) ] && echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
            done
            echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
        fi

        # 显示文件列表
        if [ $file_count -gt 0 ]; then
            echo -e "${CODE_BG}${CYAN}│${BLUE}      📄 文件列表 ($file_count 个)       ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
            for ((i=0; i<file_count; i++)); do
                [ $i -ge ${#file_names[@]} ] && break
                index=$((i + dir_count + 1))
                file_name="${file_names[$i]}"
                file_size=$(get_size "${file_paths[$i]}")
                file_icon="${file_icons[$i]}"
                aligned_name=$(align_col "$file_name" 30)
                echo -e "${CODE_BG}${CYAN}│${WHITE} [${GREEN}$index${WHITE}]${ARROW} $file_icon ${YELLOW}${aligned_name}${BLUE} [$file_size] ${CYAN}│${RESET}"
                [ $i -lt $((file_count - 1)) ] && echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
            done
            echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
        fi

        # 空目录提示
        [ $dir_count -eq 0 ] && [ $file_count -eq 0 ] && {
            echo -e "${CODE_BG}${CYAN}│${YELLOW}           📭 当前目录为空            ${CYAN}│${RESET}"
            echo -e "${CODE_BG}${CYAN}${BOX_SUB}${RESET}"
        }

        # 恢复统计+完整操作提示（关键！）
        total_count=$((dir_count + file_count))
        echo -e "${CODE_BG}${CYAN}│${MAGENTA}  总计: $total_count 项 (${dir_count}文件夹, ${file_count}文件) ${CYAN}│${RESET}"
        echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
        # 恢复操作提示符，让你明确知道怎么操作
        echo -e "${CODE_BG}${CYAN}│${GREEN}  🎯 操作: 数字选择 | b返回 | r刷新 | q退出  ${CYAN}│${RESET}"
        echo -e "${CODE_BG}${CYAN}${BOX_MID}${RESET}"
        echo -e "${CODE_BG}${CYAN}│${WHITE}  请输入选择: _________________________  ${CYAN}│${RESET}"
        echo -e "${CODE_BG}${CYAN}${BOX_BOT}${RESET}"

        # 输入处理（确保q退出、b返回等功能正常）
        echo -n ">> "
        read choice

        case $choice in
            q|Q)
                force_clear
                echo -e "${GREEN}${CHECK}  感谢使用，再见！${RESET}"
                exit 0 ;; # 确保q能正常退出
            b|B)
                current_dir="$(pwd)"
                if [ "$current_dir" != "/" ]; then
                    cd .. 2>/dev/null
                    [ $? -ne 0 ] && { echo -e "${RED}${ERROR}  无法返回上级目录${RESET}"; cd "$current_dir" 2>/dev/null; }
                else
                    echo -e "${RED}${ERROR}  已到根目录！${RESET}"
                fi
                sleep 0.3
                continue ;;
            r|R)
                continue ;; # r刷新
            [0-9]*)
                if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le $total_count ]; then
                    selected_index=$((choice - 1))
                    
                    if [ $selected_index -ge 0 ] && [ $selected_index -lt $dir_count ]; then
                        selected_dir="${dir_names[$selected_index]}"
                        if [ -d "$selected_dir" ] && [ -r "$selected_dir" ]; then
                            old_dir="$(pwd)"
                            cd "$selected_dir" 2>/dev/null
                            [ $? -ne 0 ] && { echo -e "${RED}${ERROR}  无法进入目录: $selected_dir${RESET}"; cd "$old_dir" 2>/dev/null; }
                        else
                            echo -e "${RED}${ERROR}  目录不可访问: $selected_dir${RESET}"
                        fi
                        sleep 0.3
                        continue
                    elif [ $selected_index -ge $dir_count ] && [ $selected_index -lt $((dir_count + file_count)) ]; then
                        file_index=$((selected_index - dir_count))
                        selected_file="${file_names[$file_index]}"
                        [ -e "$selected_file" ] && open_file_handler "$selected_file" || echo -e "${RED}${ERROR}  文件不存在: $selected_file${RESET}"
                        sleep 0.5
                        continue
                    else
                        echo -e "${RED}${ERROR}  选择越界！请输入1-$total_count之间的数字${RESET}"
                        sleep 0.5
                        continue
                    fi
                else
                    echo -e "${RED}${ERROR}  无效数字！请输入1-$total_count之间的数字${RESET}"
                    sleep 0.5
                    continue
                fi ;;
            *)
                echo -e "${RED}${ERROR}  无效输入！请按提示操作：数字选择 | b返回 | r刷新 | q退出${RESET}"
                sleep 0.5
                continue ;;
        esac
    done
}

# 启动主函数
main
