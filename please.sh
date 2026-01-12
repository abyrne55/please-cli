#!/usr/bin/env bash

set -uo pipefail

model=${PLEASE_CLAUDE_MODEL:-'haiku'}
options=("[I] Invoke" "[C] Copy to clipboard" "[Q] Ask a question" "[A] Abort" )
number_of_options=${#options[@]}

explain=0
debug_flag=0

initialized=0
selected_option_index=-1

yellow='\e[33m'
cyan='\e[36m'
black='\e[0m'

lightbulb="\xF0\x9F\x92\xA1"
exclamation="\xE2\x9D\x97"
questionMark="\x1B[31m?\x1B[0m"
checkMark="\x1B[31m\xE2\x9C\x93\x1B[0m"


fail_msg="echo 'I do not know. Please rephrase your question.'"

check_args() {
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -e|--explanation)
        explain=1
        shift
        ;;
      -l|--legacy)
        model="sonnet"
        shift
        ;;
      --debug)
        debug_flag=1
        shift
        ;;
      -m|--model)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          model="$2"
          shift 2
        else
          echo "Error: --model requires a model name (e.g., haiku, sonnet, opus)"
          exit 1
        fi
        ;;
      -v|--version)
        display_version
        exit 0
        ;;
      -h|--help)
        display_help
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  # Save remaining arguments to a string
  commandDescription="$*"
}


display_version() {
  echo "Please vVERSION_NUMBER"
}

display_help() {
  echo "Please - a simple script to translate your thoughts into command line commands using Claude Code"
  echo "Usage: $0 [options] [input]"
  echo
  echo "Options:"
  echo "  -e, --explanation    Explain the command to the user"
  echo "  -l, --legacy         Use Sonnet instead of Haiku"
  echo "      --debug          Show debugging output"
  echo "  -m, --model          Specify the model (haiku, sonnet, opus)"
  echo "  -v, --version        Display version information and exit"
  echo "  -h, --help           Display this help message and exit"
  echo
  echo "Input:"
  echo "  The remaining arguments are used as input to be turned into a CLI command."
  echo
  echo "Prerequisites:"
  echo "  Claude Code CLI must be installed and authenticated (run 'claude' to set up)."
}


debug() {
    if [ "$debug_flag" = 1 ]; then
        echo "DEBUG: $1" >&2
    fi
}

check_claude_cli() {
  if ! command -v claude &> /dev/null; then
    echo "Error: Claude Code CLI not found. Please install it first."
    echo "Visit https://docs.anthropic.com/claude-code for installation instructions."
    exit 1
  fi
}

strip_reasoning() {
  # Strip think blocks (both inline and multiline)
  echo "$1" | sed 's/<think>.*<\/think>//g' | sed '/<think>/,/<\/think>/d'
}

strip_markdown_fences() {
  # Remove markdown code fences (```bash, ```sh, ```, etc.)
  echo "$1" | sed 's/^```[a-zA-Z]*$//' | sed 's/^```$//' | sed '/^$/d'
}

get_command() {
  role="You translate the given input into a Linux command. Reply with ONLY the command itself - no markdown, no code fences, no backticks, no explanation.
  If you do not know the answer, answer with \"${fail_msg}\"."

  prompt="${role}

User request: ${commandDescription}"

  debug "Sending request to Claude Code CLI with model: ${model}"

  message=$(claude -p "$prompt" --model "$model" 2>/dev/null)
  exitStatus=$?

  if [ "${exitStatus}" -ne 0 ]; then
    echo "Error: Claude Code CLI request failed"
    exit 1
  fi

  message=$(strip_reasoning "$message")
  message=$(strip_markdown_fences "$message")
  command="${message}"
}

explain_command() {
  if [ "${command}" = "$fail_msg" ]; then
    explanation="There is no explanation because there was no answer."
  else
    prompt="Explain the step of the command that answers the following ${command}: ${commandDescription}. Be precise and succinct."

    message=$(claude -p "$prompt" --model "$model" 2>/dev/null)
    explanation="${message}"
  fi
}


print_option() {
  # shellcheck disable=SC2059
  printf "${lightbulb} ${cyan}Command:${black}\n"
  echo "  ${command}"
  if [ "${explain}" -eq 1 ]; then
    echo ""
    echo "${explanation}"
  fi
}

choose_action() {
  initialized=0
  selected_option_index=-1

  echo ""
  # shellcheck disable=SC2059
  printf "${exclamation} ${yellow}What should I do? ${cyan}[use arrow keys or initials to navigate]${black}\n"

  while true; do
    display_menu

    read -rsn1 input
    # Check for arrow keys and 'Enter'
    case "$input" in
      $'\x1b')
        read -rsn1 tmp
        if [[ "$tmp" == "[" ]]; then
          read -rsn1 tmp
          case "$tmp" in
            "D") # Right arrow
              selected_option_index=$(( (selected_option_index - 1 + number_of_options) % number_of_options ))
              ;;
            "C") # Left arrow
              selected_option_index=$(( (selected_option_index + 1) % number_of_options ))
              ;;
          esac
        fi
        ;;
      "i"|"I")
        selected_option_index=0
        display_menu
        break
        ;;

      "c"|"C")
        selected_option_index=1
        display_menu
        break
        ;;
      "q"|"Q")
        selected_option_index=2
        display_menu
        break
        ;;
      "a"|"A")
        selected_option_index=3
        display_menu
        break
        ;;

      "") # 'Enter' key
        if [ "$selected_option_index" -ne -1 ]; then
          break
        fi
        ;;
    esac
  done
}

display_menu() {
  if [ $initialized -eq 1 ]; then
    # Go up 1 line
    printf "\033[%dA" "1"
  else
    initialized=1
  fi

  index=0
  for option in "${options[@]}"; do
    (( index == selected_option_index )) && marker="${cyan}>${black}" || marker=" "
    # shellcheck disable=SC2059
    printf "$marker $option "
    (( ++index ))
  done
  printf "\n"
}

act_on_action() {
  if [ "$selected_option_index" -eq 0 ]; then
    echo "Executing ..."
    echo ""
    execute_command
  elif [ "$selected_option_index" -eq 1 ]; then
    echo "Copying to clipboard ..."
    copy_to_clipboard
  elif [ "$selected_option_index" -eq 2 ]; then
    ask_question
  else
    exit 0
  fi
}

execute_command() {
    save_command_in_history
    eval "${command}"
}

save_command_in_history() {
  # Get the name of the shell
  shell=$(basename "$SHELL")

  # Determine the history file based on the shell
  case "$shell" in
      bash)
          histfile="${HISTFILE:-$HOME/.bash_history}"
          ;;
      zsh)
          histfile="${HISTFILE:-$HOME/.zsh_history}"
          ;;
      fish)
          # fish doesn't use HISTFILE, but uses a fixed location
          histfile="$HOME/.local/share/fish/fish_history"
          ;;
      ksh)
          histfile="${HISTFILE:-$HOME/.sh_history}"
          ;;
      tcsh)
          histfile="${HISTFILE:-$HOME/.history}"
          ;;
      *)
          ;;
  esac

  if [ -z "$histfile" ]; then
    debug "Could not determine history file for shell ${shell}"
  else
    debug "Saving command ${command} to file ${histfile}"
    echo "${command}" >> "${histfile}"
  fi
}

copy_to_clipboard() {
  case "$(uname)" in
    Darwin*) # macOS
      echo -n "${command}" | pbcopy
      ;;
    Linux*)
      if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        echo -n "${command}" | wl-copy --primary
      else
        if command -v xclip &> /dev/null; then
          echo -n "${command}" | xclip -selection clipboard
        else
          echo "xclip not installed. Exiting."
          exit 1
        fi
      fi
      ;;
    *)
      echo "Unsupported operating system"
      exit 1
      ;;
  esac
}

init_questions() {
  systemPrompt="You will give answers in the context of the command \"${command}\" which is a Linux bash command related to the prompt \"${commandDescription}\". Be precise and succinct, answer in full sentences, no lists, no markdown."
  qaHistory=""
}

ask_question() {
  echo ""
  # shellcheck disable=SC2059
  printf "${questionMark} ${cyan}What do you want to know about this command?${black}\n"
  read -r question
  answer_question_about_command

  echo "${answer}"

  # shellcheck disable=SC2059
  printf "${checkMark} ${answer}\n"

  choose_action
  act_on_action
}

answer_question_about_command() {
  fullPrompt="${systemPrompt}

${qaHistory}
User question: ${question}"

  answer=$(claude -p "$fullPrompt" --model "$model" 2>/dev/null)

  # Append to history for multi-turn context
  qaHistory="${qaHistory}
User: ${question}
Assistant: ${answer}
"
}

function main() {
  if [ $# -eq 0 ]; then
    input=("-h")
  else
    input=("$@")
  fi

  check_args "${input[@]}"
  check_claude_cli

  get_command
  if [ "${explain}" -eq 1 ]; then
    explain_command
  fi

  print_option

  if test "${command}" = "${fail_msg}"; then
    exit 1
  fi

  init_questions
  choose_action
  act_on_action
}

# Only call main if the script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi