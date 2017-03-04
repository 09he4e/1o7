for D in *; do
    if [ -d "${D}" ]; then
        echo "${D}"   # your processing here
        cd $D
        make clean
        cd ..
    fi
done
