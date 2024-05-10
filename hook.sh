# 修改 .gitignore 不应该提交的内容
if [ ! -f ".gitignore"  ]; then
	touch ".gitignore"
fi

if [ "$(cat .gitignore | grep .idea/)" != ".idea/" ]; then
  echo ".idea/" >> ".gitignore"
fi

if [ "$(cat .gitignore | grep goframe.sh)" != "goframe.sh" ]; then
  echo "goframe.sh" >> ".gitignore"
fi

if [ "$(cat .gitignore | grep hook.sh)" != "hook.sh" ]; then
  echo "hook.sh" >> ".gitignore"
fi

# 下载lint相关的软件
## golangci-lint
if [ ! -f "$GOPATH/bin/golangci-lint" ]; then
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1
fi

## golangci-lint 的配置文件
if [ ! -f ~/.golangci.yml ]; then
echo "output:
#format: json
print-issued-lines: true
linters:
# enable-all: true
# disable:
#   - deadcode
disable-all: true
enable:
  - stylecheck
  - gosimple
  - gofmt
  - lll
  - errcheck
  - errorlint
  - govet
  - gocyclo
  - goimports
linters-settings:
lll:
  # max line length, lines longer will be reported. Default is 120.
  # '\t' is counted as 1 character by default, and can be changed with the tab-width option
  line-length: 160
  # tab width in spaces. Default to 1.
  tab-width: 1
errcheck:
  # report about not checking of errors in type assertions: \`a := b.(MyStruct)\`;
  # default is false: such cases aren't reported by default.
  check-type-assertions: false

  # report about assignment of errors to blank identifier: \`num, _ := strconv.Atoi(numStr)\`;
  # default is false: such cases aren't reported by default.
  check-blank: false
gocyclo:
  # Minimal code complexity to report.
  # Default: 30 (but we recommend 10-20)
  min-complexity: 30" > ~/.golangci.yml
fi


# 创建webhook
if [ ! -d ".git/hooks/"  ]; then
    mkdir -p ".git/hooks/"
fi

echo '#!/bin/sh

echo "1. go fmt"
if [ "$(gofmt -l -s . | wc -l)" -gt 0 ]; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n"
  printf "以下文件存在问题：";gofmt -l -s .
  printf "请执行 gofmt -l -s -w .\n"
  exit 1
fi

echo "2. go mod tidy"
if [ "$(go mod tidy  | wc -l)" -gt 0 ]; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n"
  printf "请执行 go mod tidy\n"
  exit 1
fi

echo "3. go vet"
go vet ./...
if [[ $? != 0 ]]; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n"
  printf "请手动修复\n"
  exit 1
fi

echo "4. golangci-lint run"
if [ "$(golangci-lint run ./...  | wc -l)" -gt 0 ]; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n"
  printf "以下地方存在问题：";golangci-lint run ./...
  printf "请手动修复\n"
  exit 1
fi

printf "\033[0;30m\033[42mCOMMIT SUCCEEDED\033[0m\n"

exit 0' > ".git/hooks/pre-commit"

chmod +x ".git/hooks/pre-commit"
