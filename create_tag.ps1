$version="1.31.10"
git tag -a $version -m "Release version $version"
git push origin v$version
echo "Tag $version created and pushed to origin."