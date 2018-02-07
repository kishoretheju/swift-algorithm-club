#!/usr/bin/env bash

set -e

# $1 - readme file name
function render_markdown_to_html {
  # escape escaping characters on Darwin only
  content=$(
    cat "$1"                                          \
      | sed 's/\\/\\\\/g'                             \
      | sed 's/"/\\"/g'                               \
      | sed $'s/\t/\\\\t/g'                           \
      | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\\n/g' \
  )

  # network call to GitHub API
  json="{\"text\":\"$content\",\"mode\":\"gfm\",\"context\":\"$USERNAME/swift-algorithm-club\"}"
  echo -e "$(curl -s --data "$json" -u $USERNAME:$TOKEN https://api.github.com/markdown)"
}

# download github systax highlight stylesheet
echo "> Downloading github-light.css..."
curl -s -O https://raw.githubusercontent.com/primer/github-syntax-light/master/lib/github-light.css

# slightly modify the main stylesheet
echo "> Modifying github-light.css..."
cat >> github-light.css << EOF
#container {
  margin: 0 auto;
  width: 75%;
  min-width: 768px;
  max-width: 896px;
  position: relative;
}

body {
  font-size: 18px;
}

code {
    padding: 0.2em;
    margin: 0;
    font-size: 85%;
    background-color: #f6f8fa;
    line-height: 1.45;
    border-radius: 3px
}

pre code {
    padding: 0px;
    background-color: transparent;
}

.highlight {
  margin: 0px;
  padding: 0px 16px;
  font-size: 85%;
  line-height: 1.45;
  overflow: auto;
  background-color: #f6f8fa;
  border-radius: 3px;
}

@media (max-width: 768px) {
  #container {
    position: absolute;
    margin: 0;
    width: 100%;
    height: 100%;
    min-width: 100%;
  }
}
EOF

# other markdown articles
for title in "What are Algorithms" "Big-O Notation" "Algorithm Design" "Why Algorithms"; do
  echo "> Generating $title.html..."

  cat > "$title.html" << EOF
<!DOCTYPE html>
<head>
  <title>$title</title>
  <link rel="stylesheet" type="text/css" href="github-light.css">
</head>
<body>
  <div id="container">$(render_markdown_to_html "$title.markdown")</div>
</body>
</html>
EOF
done

# if index.html does not exist, create one;
# otherwise, empty its content.
echo "> Generating index.html..."
cat > index.html << EOF
<!DOCTYPE html>
<head>
  <title>Swift Algorithm Club</title>
  <link rel="stylesheet" type="text/css" href="github-light.css">
</head>
<body>
  <div id="container">$(render_markdown_to_html README.markdown | sed 's/.markdown/.html/g')</div>
</body>
</html>
EOF

# iterate immediate directories
find . -maxdepth 1 -type d | while read folder; do
  readme=''

  # get the right extension for the README file if there is one
  if [[ -f $folder/README.md ]]; then readme="$folder/README.md"; fi
  if [[ -f $folder/README.markdown ]]; then readme="$folder/README.markdown"; fi

  # skip if there is no README or it it the README of the repository
  if [[ (-z $readme) || $readme == "./README.markdown" ]]; then continue; fi

  # render README to HTML
  name=$(basename "$folder")
  echo "> Generating $name/index.html..."

  cat > "$folder/index.html" << EOF
<!DOCTYPE html>
<head>
  <title>$name</title>
  <link rel="stylesheet" type="text/css" href="../github-light.css">
</head>
<body>
  <div id="container">$(render_markdown_to_html "$readme")</div>
</body>
</html>
EOF
done

# push to gh-pages
if [[ $CI = true ]]; then
  git checkout -b gh-pages
  git add .
  git commit -m "$Generated by TravisCI on $(date +%D)"
  git push -f https://$TOKEN@github.com/$USERNAME/swift-algorithm-club.git gh-pages
fi