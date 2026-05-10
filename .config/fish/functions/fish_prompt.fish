function fish_prompt
    set -l last_status $status

    set_color FFFFFF
    echo -n $USER

    set_color normal
    echo -n "@"
    echo -n $hostname

    set_color blue
    echo -n ' '
    echo -n (prompt_pwd)

    if not test $last_status -eq 0
        set_color red
    else
        set_color brgreen
    end

    echo -n " ↝ "

    set_color FFFFFF
end
