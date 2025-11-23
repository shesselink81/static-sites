$version="2.0.0"
git tag -a v$version -m "Release version $version"
git push origin v$version
echo "Tag v$version created and pushed to origin."