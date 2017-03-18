for D in *; do
    if [ -d "${D}" ]; then
        echo "${D}"   # your processing here
        cd $D
        echo $(pwd)
        ls *.ko 
        cd ..
    fi
done
