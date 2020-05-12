#!/bin/bash
echo "push blog source to github"
git pull
git add .
git commit -s -m "upd |> commit soure to github"
git push origin master
echo "push blog source to github end"
