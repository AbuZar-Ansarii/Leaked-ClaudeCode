#!/data/data/com.termux/files/usr/bin/bash

# ── Colors & Config ──────────────────────────
CYN='\033[1;36m'
GRN='\033[1;32m'
YLW='\033[1;33m'
RED='\033[1;31m'
B='\033[1m'
R='\033[0m'
LAUNCHER="$PREFIX/bin/claude"

header() {
    clear
    echo -e "${CYN}${B}OpenClaude Termux - Ollama Edition${R}"
    echo "───────────────────────────────────────────"
}

# ── Ollama Validation ────────────────────────

check_ollama_status() {
    echo -e "\n${CYN}Checking Ollama Server...${R}"
    
    # 1. Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}✖ Ollama is not installed!${R}"
        echo -e "Run: ${YLW}pkg install ollama${R}"
        exit 1
    fi

    # 2. Check if Server is running
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo -e "${RED}✖ Ollama server is NOT running!${R}"
        echo -e "Please open a NEW Termux session and run: ${YLW}ollama serve${R}"
        echo -e "Then come back and restart this script."
        exit 1
    fi
    echo -e "${GRN}✔ Ollama Server is live.${R}"
}

# ── Model Selection ──────────────────────────

select_ollama_model() {
    echo -e "\n${B}Select an Ollama Model to use:${R}"
    echo "───────────────────────────────────────────"
    
    # Pre-defined list from your request
    MODELS=(
        "glm-5.1:cloud"
        "minimax-m2.7:cloud"
        "gemma4:31b-cloud"
        "qwen3.5:397b-cloud"
        "ministral-3:3b-cloud"
        "nemotron-3-super:cloud"
        "kimi-k2.5:cloud"
        "gemini-3-flash-preview"
    )

    for i in "${!MODELS[@]}"; do
        echo -e "${CYN}$((i+1)))${R} ${MODELS[$i]}"
    done
    echo -e "${YLW}$(( ${#MODELS[@]} + 1 )))${R} Enter Custom Model Name"
    
    echo -n -e "\nChoose [1-$(( ${#MODELS[@]} + 1 ))]: "
    read choice

    if [ "$choice" -eq "$(( ${#MODELS[@]} + 1 ))" ]; then
        read -p "Enter model name: " SELECTED_MODEL
    else
        SELECTED_MODEL=${MODELS[$((choice-1))]}
    fi

    echo -e "\n${GRN}Preparing model: ${B}$SELECTED_MODEL${R}"
    # Pull the model to ensure it exists locally
    ollama pull "$SELECTED_MODEL"
}

# ── Launcher Generation ──────────────────────

generate_ollama_launcher() {
    cat << EOF > "$LAUNCHER"
#!/data/data/com.termux/files/usr/bin/bash
# OpenClaude redirected to local Ollama
export CLAUDE_CODE_USE_OPENAI=1
export OPENAI_API_KEY="ollama"
export OPENAI_BASE_URL="http://localhost:11434/v1"
export OPENAI_MODEL="$SELECTED_MODEL"
export ANTHROPIC_API_KEY=""

# Execute with proot for filesystem access
proot -b \$TMPDIR:/tmp -b /system -b /sdcard openclaude \$@
EOF
    chmod +x "$LAUNCHER"
}

# ── Main Execution ───────────────────────────

header
check_ollama_status
select_ollama_model

echo -e "\n${CYN}Installing System Dependencies...${R}"
pkg install nodejs git curl proot termux-api -y
npm install -g @gitlawb/openclaude

generate_ollama_launcher

echo -e "\n${GRN}${B}Setup Complete!${R}"
echo -e "Run '${CYN}claude${R}' to start."