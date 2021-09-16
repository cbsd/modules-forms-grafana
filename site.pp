# my_module_dir variable define in puppet script

# Linux required -i'', not "-i ''" for inplace
os=$( uname -s )
case "${os}" in
	Linux)
		# Linux require -i'', not -i ' '
		sed_delimer=
		;;
	FreeBSD)
		sed_delimer=" "
		;;
esac

generate_manifest()
{

cat <<EOF
class { 'profiles::services::grafana': }
EOF

# copy sample dashboard into jail
if [ -n "${data}" ]; then
	if [ ! -d ${data}/usr/local/etc/grafana/dashboard/node-exporter-full_rev23.json ]; then
		if [ -r ${my_module_dir}/dashboard/node-exporter-full_rev23.json ]; then
			[ ! -d ${data}/usr/local/etc/grafana/dashboard ] && mkdir -p ${data}/usr/local/etc/grafana/dashboard
			cp -a ${my_module_dir}/dashboard/node-exporter-full_rev23.json ${data}/usr/local/etc/grafana/dashboard/node-exporter-full_rev23.json
		fi
	fi
fi

}

generate_hieradata()
{
	local my_common_yaml="${my_module_dir}/common.yaml"
	local datasource_part_header="${my_module_dir}/datasource_part_header.yaml"
	local datasource_part_body="${my_module_dir}/datasource_part_body.yaml"
	local dashboard_part_header="${my_module_dir}/dashboard_part_header.yaml"
	local dashboard_part_body="${my_module_dir}/dashboard_part_body.yaml"
	local _val _tpl

	if [ ! -r ${datasource_part_header} ]; then
		echo "no such ${datasource_part_header}"
		exit 0
	fi

	if [ ! -r ${datasource_part_body} ]; then
		echo "no such ${datasource_part_body}"
		exit 0
	fi
	if [ ! -r ${dashboard_part_header} ]; then
		echo "no such ${dashboard_part_header}"
		exit 0
	fi

	if [ ! -r ${dashboard_part_body} ]; then
		echo "no such ${dashboard_part_body}"
		exit 0
	fi

	local form_add_dashboard=0
	local form_add_datasource=0

	if [ -f "${my_common_yaml}" ]; then
		local tmp_common_yaml=$( mktemp )
		/bin/cp ${my_common_yaml} ${tmp_common_yaml}
		for i in ${param}; do
			case "${i}" in
				# start with dashboard  custom
				datasource_name[1-9]*)
					form_add_datasource=$(( form_add_datasource + 1 ))
					continue;
					;;
				dashboard_name[1-9]*)
					form_add_dashboard=$(( form_add_dashboard + 1 ))
					continue;
					;;
				-*)
					# delimier params
					continue
					;;
				Expand)
					# delimier params
					continue
					;;
			esac
			eval _val=\${${i}}
			_tpl="#${i}#"
			# Note that on Linux systems, a space after -i might cause an error
#			sed -i${sed_delimer}'' -Ees:"${_tpl}":"${_val}":g ${tmp_common_yaml}
			sed -i${sed_delimer}'' -Ees@"${_tpl}"@"${_val}"@g ${tmp_common_yaml}
		done
	else
		for i in ${param}; do
			eval _val=\${${i}}
		cat <<EOF
 $i: "${_val}"
EOF
		done
	fi

	# custom dashboard
	if [ ${form_add_dashboard} -ne 0 ]; then
		cat ${dashboard_part_header} >> ${tmp_common_yaml}
		for i in ${param}; do
			case "${i}" in
				dashboard_name[1-9]*)
					;;
				*)
					continue
					;;
			esac

			eval _val=\${${i}}
			[ -z "${_val}" ] && continue

			_tpl="#dashboard_name#"
			sed -Ees/"${_tpl}"/"${_val}"/g ${dashboard_part_body} >> ${tmp_common_yaml}
		done
	fi

	# custom datasource
	if [ ${form_add_datasource} -ne 0 ]; then
		cat ${datasource_part_header} >> ${tmp_common_yaml}
		tmpfile=$( mktemp )
		cp -a ${datasource_part_body} ${tmpfile}
		for i in ${param}; do
			case "${i}" in
				datasource_name[1-9]*)
					_tpl="#datasource_name#"
					;;
				datasource_url[1-9]*)
					_tpl="#datasource_url#"
					;;
				datasource_type[1-9]*)
					_tpl="#datasource_type#"
					;;
				datasource_access_mode[1-9]*)
					_tpl="#datasource_access_mode#"
					;;
				datasource_is_default[1-9]*)
					_tpl="#datasource_is_default#"
					;;
				*)
					continue
					;;
			esac

			eval _val="\${${i}}"
			[ -z "${_val}" ] && continue

			rule_name="XXX"		# concat from all field
			sed -i${sed_delimer}'' -Ees@"${_tpl}"@"${_val}"@g ${tmpfile}
		done
		cat ${tmpfile} >> ${tmp_common_yaml}
		cp -a ${tmpfile} /tmp/x.yaml
		rm -f ${tmpfile}
	fi

	# custom dashboard
	if [ ${form_add_dashboard} -ne 0 ]; then
		cat ${dashboard_part_header} >> ${tmp_common_yaml}
		tmpfile=$( mktemp )
		cp -a ${dashboard_part_body} ${tmpfile}
		for i in ${param}; do
			case "${i}" in
				dashboard_name[1-9]*)
					_tpl="#dashboard_name#"
					;;
				dashboard_template[1-9]*)
					_tpl="#dashboard_template#"
					;;
				*)
					continue
					;;
			esac

			eval _val="\${${i}}"
			[ -z "${_val}" ] && continue

			rule_name="XXX"		# concat from all field
			sed -i${sed_delimer}'' -Ees@"${_tpl}"@"${_val}"@g ${tmpfile}
		done
		cat ${tmpfile} >> ${tmp_common_yaml}
		cp -a ${tmpfile} /tmp/x.yaml
		rm -f ${tmpfile}
	fi

	cat ${tmp_common_yaml}
}
