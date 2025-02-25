#!/usr/bin/env sh

# Получение последнего тега
latest_tag_info=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/tags" | jq -r '.[0]')

if [ -z "$latest_tag_info" ]; then
  echo "No tags found."
  exit 1
fi

# Получение времени создания текущего комита
commit_created_at=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/commits/$CI_COMMIT_SHA" | jq -r '.created_at')

latest_tag_name=$(echo "$latest_tag_info" | jq -r '.name')
latest_tag_created_at=$(echo "$latest_tag_info" | jq -r '.commit.created_at')

# Получение MR, объединенных после создания последнего тега и до конкретного коммита
mrs=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests?state=merged&updated_after=$latest_tag_created_at&updated_before=$commit_created_at")
# Получение текушего МР
current_mr=$(curl --fail --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/commits/$CI_COMMIT_SHA/merge_requests")



# Вывод ссылки на последний тег в формате Markdown
echo "# CHANGELOG"
echo "Changes from previous tag [$latest_tag_name]($CI_PROJECT_URL/-/tags/$latest_tag_name)"

if [ -z "$current_mr" ] || [ "$current_mr" == "[]" ]; then
  echo "No merge requests found for commit $CI_COMMIT_SHA."
else
# Вывод MR в формате Markdown тещего MR
echo "$current_mr" | jq -r '.[] | "- [MR #\(.iid)](\(.web_url)): \(.title) by \(.author.name)"'
fi
# Проверка и вывод MRs
if [ -z "$mrs" ] || [ "$mrs" == "[]" ]; then
  echo "No merge requests found since the latest tag."
  exit 1
  else
# Вывод MR в формате Markdown
echo "$mrs" | jq -r '.[] | "- [MR #\(.iid)](\(.web_url)): \(.title) by \(.author.name)"'
fi



