# `aws_exp <profile>` sources ~/bin/aws_exp.sh so its exports land in this shell, like cf_exp.
aws_exp() { source "$HOME/bin/aws_exp.sh" "$@"; }
