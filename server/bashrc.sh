# functions
norm_cour()
{
    for i in $(ls); do
        if [ -f "$i" ]
            then
              res=`echo $i | sed 's/^_[a-z0-9]*_//'`
            if [ "$i" != "$res" ]
                then
                  mv "$i" "$res"
            fi
        fi
    done
}

print_to_python3_notebook()
{
    sed -i 's/print \(.*\)\"/print\(\1\)\"/g' "$1"
}
## some commands
# find `pwd` -type f -regextype posix-egrep -regex '.*\.(ipynb|py)' -exec tar cjvf all_scripts.tbz {} \+
