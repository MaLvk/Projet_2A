#!/bin/sh
# This script was generated using Makeself 2.2.0

umask 077

CRCsum="1802247797"
MD5="e91b319ceac8a6200fd2aefa5b3ed89b"
TMPROOT=${TMPDIR:=/tmp}

label="STM STLink-Server installer"
script="./setup.sh"
scriptargs=""
licensetxt=""
targetdir="makeself_dir_hR1KbM"
filesizes="153600"
keep="y"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo $licensetxt
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
 	eval $finish; exit 1        
        break;    
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test "$noprogress" = "y"; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd bs=$offset count=0 skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.2.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    if test "$quiet" = "n";then
    	MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 501 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test `basename $MD5_PATH` = digest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test $md5 = "00000000000000000000000000000000"; then
				test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test "$md5sum" != "$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test $crc = "0000000000"; then
			test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test "$sum1" = "$crc"; then
				test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test "$quiet" = "n";then
    	echo " All good."
    fi
}

UnTAR()
{
    if test "$quiet" = "n"; then
    	tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

    	tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=y
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 156 KB
	echo Compression: none
	echo Date of packaging: Wed Jun  9 12:03:34 UTC 2021
	echo Built with Makeself version 2.2.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--nocomp\" \\
    \"--nox11\" \\
    \"--notemp\" \\
    \"/tmp/makeself_dir_hR1KbM\" \\
    \"st-stlink-server.2.0.2-3-linux-amd64.install.sh\" \\
    \"STM STLink-Server installer\" \\
    \"./setup.sh\""
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"makeself_dir_hR1KbM\"
	echo KEEP=y
	echo COMPRESS=none
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=156
	echo OLDSKIP=502
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 501 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "cat" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 501 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "cat" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test "$quiet" = "y" -a "$verbose" = "y";then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

MS_PrintLicense

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	if test "$quiet" = "n";then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 501 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 156 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test "$quiet" = "n";then
	MS_Printf "Uncompressing $label"
fi
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 156; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (156 KB)" >&2
        if test "$keep" = n; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "cat" | ( cd "$tmpdir"; UnTAR x ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test "$quiet" = "n";then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
./                                                                                                  0000700 0117457 0127674 00000000000 14060127026 010444  5                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ./stlink-server                                                                                     0000755 0117457 0127674 00000377600 14060127025 013230  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 ELF          >    �@     @       @�         @ 8 	 @ % "       @       @ @     @ @     �      �                   8      8@     8@                                          @       @     |�      |�                    ��      ��`     ��`     �      @                    ��      ��`     ��`                                T      T@     T@     D       D              P�td   �      �@     �@                        Q�td                                                  R�td   ��      ��`     ��`                          /lib64/ld-linux-x86-64.so.2          GNU                        GNU �l�X�(���r8�\   I         ��  DI   K   N   BE���|�qX���9�������                        �                     I                     N                     P                     �                     �                                            �                     3                     f                     P                     �                     j                      �                     �                     v                     �                     D                     �                     �                      �                     2                     -                     
                                          p                     �                      �                                           "                     �                      8                     �                     (                     �                     �                     -                       �                     A                     �                      �                     [                     �                     \                     �                     �                      �                     �                                          n                     
                     �                     �                                           �                     �                     �                     <                       �                     _                     H                     �                     �                     �                                          P                       �                     �                     �                     �                     �                     z                     �    ��`             �     �`             �    ��`             �    H@             i    ��`            �     $�@             b    ��`             libusb-1.0.so.0 _ITM_deregisterTMCloneTable __gmon_start__ _Jv_RegisterClasses _ITM_registerTMCloneTable libusb_release_interface libusb_get_device_descriptor libusb_get_configuration libusb_close _fini libusb_bulk_transfer libusb_get_device_list libusb_get_config_descriptor libusb_free_device_list libusb_get_string_descriptor_ascii libusb_open libusb_error_name libusb_get_device libusb_get_version libusb_claim_interface libusb_control_transfer libusb_hotplug_deregister_callback libusb_init libusb_set_configuration libusb_exit libusb_free_config_descriptor libpthread.so.0 send recv __errno_location accept sigaction libc.so.6 socket fflush strcpy htons sprintf fopen strncmp __isoc99_sscanf signal strncpy __stack_chk_fail listen select strdup strtok strlen getaddrinfo memset bind getnameinfo fputc inet_addr fputs strtok_r memcpy strtoul setsockopt malloc optarg stderr ioctl getopt_long usleep gettimeofday atoi freeaddrinfo strerror __libc_start_main vfprintf free _edata __bss_start _end /src/staging/libusb/linux64/lib GLIBC_2.2.5 GLIBC_2.7 GLIBC_2.14 GLIBC_2.4                                                                                                                4         ui	   	        p         ii
           `�`                   h�`                   p�`        
   �@����%:�  h   �0����%2�  h   � ����%*�  h
�  h   ������%�  h   ������%��  h   �����%��  h   �����%��  h   �����%��  h   �����%��  h   �p����%��  h   �`����%��  h   �P����%��  h   �@����%��  h   �0����%��  h   � ����%��  h   �����%��  h   � ����%��  h   ������%��  h    ������%��  h!   ������%��  h"   ������%z�  h#   �����%r�  h$   �����%j�  h%   �����%b�  h&   �����%Z�  h'   �p����%R�  h(   �`����%J�  h)   �P����%B�  h*   �@����%:�  h+   �0����%2�  h,   � ����%*�  h-   �����%"�  h.   � ����%�  h/   ������%�  h0   ������%
�  h1   ������%�  h2   ������%��  h3   �����%��  h4   �����%��  h5   �����%��  h6   �����%��  h7   �p����%��  h8   �`����%��  h9   �P����%��  h:   �@����%��  h;   �0����%��  h<   � ����%��  h=   �����%��  h>   � ����%��  h?   ������%��  h@   ������%��  hA   ������%��  hB   ������%z�  hC   �����%2�  f�        1�I��^H��H���PTI�� �@ H����@ H���<@ �w����fD  ���` UH-��` H��H��v�    H��t]���` ��f�     ]�@ f.�     ���` UH���` H��H��H��H��?H�H��t�    H��t]���` �� ]�fD  �=A�   uUH���n���]�.�  ��@ ���` H�? u� �    H��t�UH����]�z���UH��H�� �}�H�u�H�U�E��¾H�@ �   �    ��  �E���t��X�@ �������  ��	  �E����6�����UH��H��   dH�%(   H�E�1�H��`�����   �    H������Hǅ`����@ �E�   H��`����    H�ƿ   ������\�����\��� y#��\����¾h�@ �    �    �I  �    �$���  ��~���@ �   �    �#  �   H�M�dH3%(   t�\�����UH��H�}�H�E�H� H;E���]�UH��}�H�E�    H�<�  H�E��/H�E�H�E�H�E�H�E��E�H;E�uH�E��H�E�H�E�H� H�E�H�}�P�` uǸ    ]�UH����  ��~���@ �   �    �q  �[  �  �}  �   ����UH��H��   dH�%(   H�E�1�Hǅ0���   ǅ���    ǅ���    ���  ����  �Ȣ@ �   �    ��  �  �����ƅ��� �    �   H��p���H����H����ʉ� �����$���ǅ���    H��  H��(����   H��(���H��8���H��8���H��@���H��@����@�P?��H�����Hc�H���p���H��@����@���Ѓ�?)к   ��H��H��H	�H��Hc�H���p��������H��(���H� H��(���H��(���P�` �f������  ��t4���  9����&�]�  ��~��@ �   �    ��  ƅ���H��0���H��`���Hǅh���    H��`���H��p���I�й    �    H�ƿ   �|������������� ��   �$���� ����������t������¾��@ �    �    �E  �'���  ��~������¾�@ �   �    �  ����� t�z����������  ���- �����  ����� u@�U�  ��~H��0���H�¾@�@ �   �    ��  ����� �N  �����D  ����� t&��  ��~�m�@ �   �    �  �U�   H���  H��(�����  H��(���H��H���H��H���H��P�������� ��  H��P����@�P?��H���H�H���p���H��P����@���Ѓ�?)к   ��H��H��H!�H���j  �����H��P����@��t/�G�  ��~$H��P����@���¾��@ �   �    �  H��P����@��tSH��P���H���  H����   ����� ��   ���  ��~���@ �   �    �Y  �    �+  ��   H��P���H���E  ��������������tH��P���H����  ������   H��P����@���.���H��P���H����-  H��X���H��X��� tH��X����@$���e#  �
�    �-+  �+�  ��~�P�` �ȣ@ �   �    �  H��P���H���&  ����H��(���H� H��(���H��(���P�` ������P�` �S��������Y����H�E�dH3%(   t������UH��H�� �}�H�u�dH�%(   H�E�1��E�    H�U�H�u��E�I�й �@ � �@ ���g����E�}��u���  ����  �  �E�  ��~�E�¾�@ �   �    �  �E��ht2��h��atF��dtl���  ��p�8  ��vt��l��   �  �O�     �w  �D�     �h  ���  ��~��@ �   �    �>  �9�  �=  ���  ��~1H���  H��t	H���  ��)�@ H�¾+�@ �   �    ��  H���  H��t	H���  ��)�@ H�������@�  ��   �5�  ��~H�i�  H�¾=�@ �   �    �  H�K�  H����   ���  ��~H�0�  H�¾M�@ �   �    �g  H��  H���Z  �`���  ��~1H���  H��t	H���  ��^�@ H�¾c�@ �   �    �  H���  H��t	H���  ��^�@ H���  ��������n�@ ������    ��  ���@ ������    ��  ���@ ������    �  �إ@ ������    �  ��@ ������    �  �x�@ ������    �p  ���@ ������    �\  ����������6�  ��t��  �    �����    H�M�dH3%(   t�z�����UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��]�UH��H��H�}�H�E�H���D���H���  ���UH��H��`H�}�H�u�dH�%(   H�E�1�H�E���H�U�H�E�H��jA�    A�    �.   H������H���E��}� t�E��¾�@ �   �    �F  �H�E�H�¾�@ �   �    �)  �H�E�dH3%(   t�f�����UH��H��   dH�%(   H�E�1�H�E�   ƅu��� �E�    ���      �D�  ��~�0�@ �   �    �  �%�  ��~�X�@ �   �    �  H�E��0   �    H���v����E�   �E�   �E�   �E�   ���  ��~(H�x�  H�i�  H��H�¾��@ �   �    �5  H�P�  H�¾��@ �   �    �  H�2�  H�M�H�U�H�ƿ    �m�����t(����� �E��E��¾��@ �    �    ��  �N  H�E�H��u�ا@ �    �    �  �,  ��  ��~���@ �   �    �  H�E�H�E��E�   ��  ���  ��~+H�E�H�H �U�H�E�I�ȉ�H�¾8�@ �   �    �D  H�E��PH�E��HH�E��@�Ή�������E��}��u<������ �E��E��¾p�@ �    �    ��  ���@ �    �    ��  �E  �M�  ��~�E��¾Ȩ@ �   �    �  H���  H�������f��v���f�E� ��v���������f�E��@ �����E�H�E�   H������ǅx���   H��x����E�A�   H�Ѻ   �   ���e����E��}��u+������ �E��E�������H�¾��@ �    �    �  ǅ|��� �  H��|����E�A�   H�Ѻ   �   �������E��}��u+����� �E��E����V���H�¾(�@ �    �    �
  H�E�  H�E�H�E�H� H�E��   H�E�H�E�H�E�H�E��+�  ��~H�E��@�¾�@ �   �    �
  H�E��@���tAH�E��@���������  ��~H�E��@�¾?�@ �   �    �U
  H�E��@����H�E�H�E�H�E�H� H�E�H�}�P�` �Z�����      ���  ��~�`�@ �   �    � 
  ���UH��H���   H��H���dH�%(   H�E�1�ǅT����   Hǅh���    Hǅ`���   ǅX���    ��  ��~*H��H����@H��H���H�щ¾��@ �   �    �}	  H��p���H��H��H����@H��T���H�Ή��j�����\�����\����u<������ ��X�����X��� t��X����¾ȫ@ �    �    �	  �    �  ��T���Hc�H��p���H��H���:���H��H����@H��`����!T  �Ǹ    ��������u)�x���� ��X�����X����¾�@ �    �    �  �  H��h���H��h��� u#�D�@ �    �    �x  ��\����������VH��h�����\����PH��h����@ H��h����P�` H���������  ��~��\����¾�@ �   �    �  H��h���H�M�dH3%(   t�J�����UH��H�� H�}��E� H�E��� �  ��t�C�  ��~� �@ �   �    �  H�E�H����  �    H������H�E�H�pH�E�@�    ��  ��� ����E��}� y]�"���� �E��}�u(���  ��~�P�@ �   �    �F  �E� �   �}� t�E��¾��@ �    �    �  �E��q�}� u���@ �    �    ��  �E��QH�E苐$�  �E��H�E艐$�  H�E�ƀ �  �}�H�E�H���  H�E�H�PH�E�H�pH�E�A��H���m   �E���UH��H���   H��8�����4���H��(���dH�%(   H�E�1�ƅC��� ǅH���    ǅL���    ǅD���    Hǅ`���    Hǅh���P�  ��  �    �   H��p���H����H����ʉ�P�����T���H��8����@�P?��H�����Hc�H���p���H��8����@���Ѓ�?)к   ��H��H��H	�H��Hc�H���p���H��8����@�xH��`���H��p���I�й    �    H���x�����X�����X��� �F  ��4���+�D�����H��8����@H��(����    ���������L�����L��� ��   ������ ��\���ǅL���    ��\���t	��\���uZ��\���u
�P�  ������H�����H�����  �Q�  ��~��\����¾�@ �   �    �  ƅC����Q  ��\��� t'��  ��~��\����¾ �@ �   �    �  ƅC����  ��L��� u �X�@ �    �    �Y  ƅC�����   ��L����D�����L���H�H�(�����   ��X��� u?��H�����H�����   �|�  ��~���@ �   �    ��  ƅC����   ����� ��\�����\���u@��H�����H���~^�+�  ��~��\����¾�@ �   �    �  ƅC����.���  ��~��\����¾ �@ �   �    �h  ƅC�����D���;�4���s��C�������������D���H�M�dH3%(   t�y�����UH��H�� H�}��E� H�E��� �  ����uH�E苀�  ��(�a�  ���K  �S�@ �   �    ��  �2  H�E苀�  Hc�H�E�H�HH�E苀�  ��H�4H�E�@�    ���'����E��}��uO�9���� �E��}�u�p�@ �    �    �h  �E� ��   �E��¾��@ �    �    �F  �E��   H�E苐�  �E��H�E艐�  H�E苀�  +E���H�E艐�  H�E苀�  ��uH�E�ƀ �   H�E苐(�  �E��H�E艐(�  H�E苀�  ��t0�7�  ��~%H�E苐�  �E��щ¾Ȯ@ �   �    �  �E���UH��H��0dH�%(   H�E�1�H�E�    H���/����Eԃ}� y�E�H�H�E��7H�E�Hi��  H�M�H���S㥛� H��H��H��H��H��?H)�H��H�H�E�H�E�H�}�dH3<%(   t�\�����UH��H���   ��,���H�� ���H��`���H��h���L��p���L��x�����t )E�)M�)U�)]�)e�)m�)u�)}�dH�%(   H��H���1����  �����  ���  9�,���gǅ0���   ǅ4���0   H�EH��8���H��P���H��@�����,����u2H�.�  H��0���H�� ���H��H���-���H��  H���.�����H��H���dH3%(   t�T�����UH��H���   �����H�����H��`���H��h���L��p���L��x�����t )E�)M�)U�)]�)e�)m�)u�)}�dH�%(   H��H���1����  �����  ��  9�����2  ǅ0���   ǅ4���0   H�EH��8���H��P���H��@������  ����   ������H��  )Љ�,����
   �����_����� x"�����H�H��@�@ H�}�  H��H���Z���H�k�  H��0���H�����H��H���j���H�K�  H�ƿ
   ����H�7�  H���W�����H��H���dH3%(   t�}�����UH�����     H��  H���  �s���H��  �]�UH��H�� H�}�H�E�{�@ H�������H�E�H�}� tH�E�H���  �    ��UH��H�ĀH�}�H�u�H�U�dH�%(   H�E�1�H�v2.0.2-3H�E��E� H�E�    H�E�    H�E�    H�U�H�Eྀ�@ H�������H�E�H�}� tH�E�H�E�H�¾��@ �    ����H�E�H�}� tH�E�H�¾��@ �    ����H�E�H�}� tH�U�H�E����@ H���m���H�}� �#  H�}� �  H�}� �
   �    H�������H�E�H�E��
   �    H�������H�E�H�E��
   �    H������H�E؋��  ��~+H�E؉�H�EЉ�H�E�A�ȉщ¾��@ �   �    �V��������H9E�w<�����H9E�w1�����H9E�w&H�E�H�U�H�H�E�H�U�H�H�E�H�U�H��   H�E�H�     H�E�H�     H�E�H�     �Z�  ��~X���@ �   �    ������BH�E�H�     H�E�H�     H�E�H�     ��  ��~�ɯ@ �   �    �������H�E�dH3%(   t�������UH��H�� dH�%(   H�E�1�H�E�    H�E�    H�E�    H�U�H�M�H�E�H��H���i���H�M�H�U�H�E�H�ƿ�@ �    �����H�E�dH3%(   t�L�����UH��H�� �}�H�u��E�    ������@ ������   �
E��E���1E��E��E�H;E�r΋E���E��E���1E��E���E��E�]�UH��H�� H�}�H�E�H���	���H��H�E�H��H���i�����H�E�H�E����n   H��u�    ��   ��UH��H��H�}���  ��~)H�E�H�PH�E�H� H��H�¾�@ �   �    �a���H�E�H������H�E�H����������UH��H��0�}�H�ֲ  H�E��bH�E�H�E�H�E�H�E����  ��~*H�E��H4H�U��E�A��H�щ¾�@ �   �    �����H�E��@4;E�uH�E��>H�E�H� H�E�H�}��` u��.�  ��~�E܉¾H�@ �   �    �����    ��UH��H��0H�}�H�E�H������H��H�E�H��H��������H�E�H��  H�E��_H�E�H�E�H�E�H�E����  ��~$H�E��P4H�E���H�¾`�@ �   �    ����H�E��@4��H;E�uH�E��@H�E�H� H�E�H�}���` u��]�  ��~H�E�H�¾��@ �   �    ������    ��UH��}��E�    H�Q�  H�E��-H�E�H�E�H�E�H�E��E�;E�uH�E���E�H�E�H� H�E�H�}��` uɸ    ]�UH�忐�` ��  ]�UH��H�� �}�H�u��E���~���H�E�H�}� ��   ���  ��~ H�U��E�H�щ¾��@ �   �    ����H�E�H�@H�U�H��H��H�������H�E��P*H�E�f�P&H�E��P(H�E�f�P$H�E��@( H�E�H�@H�������H��H�E�H�@H��H���C�����H�E��P4��  ��~5H�E�H�HH�E��@&��H�E��@4I�ȉщ¾�@ �   �    �V���H�E��P4H�E���   ��E�¾�@ �    �    �)����  ��UH��H���}�H�u�H�U��E�H�։�����H��uH�E�� ��    ��UH��H��0�}�H�uЋE܉�����H�E�H�}� �  �1�  ��~)H�EЋ�0�  H�E��@4�щ¾X�@ �   �    ����H�U�H�E�H��H���n  H�E�H�E�H�@H�@H���Y  H�}� �N  H�E�H����O  �E���  ��~6H�E�H�@H�HH�E�H�@H� �U�I�ȉ�H�¾��@ �   �    �
����}� ��   H�E�H����:  �E�}� u-�W�  ���V  �E܉¾�@ �   �    ������8  �*�  ��~�E�¾��@ �   �    ����H�E�H�@H�@    H�E�H�������H�E�H������H�E�    ��   �ѭ  ��~�E܉¾�@ �   �    �A���H�E�H�@H�@    H�E�H������H�E�H������H�E�    �   H�}� u!�q�  ��~u�P�@ �   �    ������_�P�  ��~TH�E�H�@H�@H�¾��@ �   �    �����/� �  ��~�E܉¾��@ �   �    ����H�E�    ��H�E���UH���JO  �]�UH���@B  H�]�UH��H�� �}�E����	  H�E�H�}� tH�E�H�@H�@�U��H���A4  ����@ �    �    �������  ��~�E�¾��@ �   �    ������E���  H���UH��H��P�}�H�u�H�U�H�M�L�E��E܉��[	  H�E��E�    H�}� t+H�E��@ ��tH�E�H�@H�@H�E��}� ��   ��   H�}� t8H�E��@ ����t)H�E��@$�¾(�@ �    �    �P���H�������   H�}� tH�E��@$�¾h�@ �    �    � �������@ �    �    �
���H�������rH�EЋ ��u!H�EЋ@��H�M�H�E�H��H���-  �E��CH�E�H�HH�E�H�PH� H�H�QH�EЋ ��H�EЋ@��H�u�H�E��щ�H���+  �E�E���UH��H�}�H�E�    H�E�H� H�E��H�E�H�E�H� H�E�H�E�H;E�u�H�E�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��P�` �n���]�UH��H���h�  �����H�E�H�}� u%�H�  ����   ���@ �   �    �����q�#�  ��~H�E�H�¾��@ �   �    ����H�E��h�  �    H���m���H�E��@�����h�  ���_�  �Y�  H�E���0�  H�E�ƀ �   H�E���UH��H��H�}�H�E�H���������  ��~H�E�H�¾Դ@ �   �    ��������UH��H��H�}��^�  ��~)H�E�H�PH�E�H� H��H�¾�@ �   �    ����H�E�H���b���H�E�H���f������UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��}��E�    H���  H�E��;H�E�H�E�H�E�H�E�H�E��@ ��tH�E�H�@�@4;E�u�E�H�E�H� H�E�H�}��` u��E�]�UH��H��0�}�H�2�  H�E��lH�E�H�E�H�E�H�E�H�E��@ ��tEH�E�H�@�@4;E�u5�ڧ  ��~"H�E��@$�U܉щ¾ �@ �   �    �A���H�E��@  H�E�H� H�E�H�}��` u����UH���E�    H���  H�E���E�H�E�H� H�E�H�}���` u�E�]�UH��c�  �P�Z�  ]�UH��H�� H�}�H�u�(   ����H�E�H�}� tnH�E�H�U�H�PH�E�H�U�H�P������H�E��P$H�E��@ ��  ��~"H�U�H�E�H��H�¾h�@ �   �    �V���H�E����` H�������-���  ��~"H�U�H�E�H��H�¾��@ �   �    ����H�E���UH��H��@H�}�H�u��E� H�E�    H��  H=��` txH�p�  H�E��_H�E�H�E�H�E�H�E�H�E��@ ��t8H�EȋP4H�E�H�@�@49�u"H�E���0�  H�E�H�@��0�  9�u�E��H�E�H� H�E�H�}��` u���E� �E߃�����   �ƥ  ��~ H�E���0�  �¾ߵ@ �   �    �/���H�U�H�E�H��H���F���H�E�H�E�H�E�H�}� tq�u�  ��~fH�E��@$H�U�H�щ¾ �@ �   �    ������@�D�  ��~H�E��@$�¾#�@ �   �    ����H�E�H�U�H�PH�E�H�U�H�PH�E���UH��H���}����  ��t�V���;E�u	�F�  �&�դ  ��~�8����¾A�@ �   �    �C�����  ��UH��H��0�}܋��  ��~�E܉¾`�@ �   �    �����E܉��  H�E�H�}� ��  H�E��@ ���  H�E�H�@�@4�������E�9�  ��~&H�E�H�@�@4�U�щ¾��@ �   �    �����}��  ���  ��~$H�E��@$H�U�H�щ¾ȶ@ �   �    �c���H�E�H�@H�E��ã  ��~H�E�H�@H�¾ �@ �   �    �-���H�E�H�@H���e/  H�E��@8 ���  ��~������¾C�@ �   �    �����H�E�H�@H�@    �   �C����O�?�  ��~�X�@ �   �    ����� �  ��~�����¾C�@ �   �    �����   �����H�E�H������H�E�H��������    ��UH��}�H��  H�E��-H�E�H�E�H�E�H�E�H�E��@$;E�uH�E��H�E�H� H�E�H�}��` uɸ    ]�UH��H�}�H���  H�E��=H�E�H�E�H�E�H�E�H�E؋�0�  H�E�H�@��0�  9�uH�E��H�E�H� H�E�H�}��` u��    ]�UH��}��E�    H�-�  H�E��;H�E�H�E�H�E�H�E�H�E��@ ��tH�E�H�@�@4;E�u�E�H�E�H� H�E�H�}��` u��E�]�UH��H�}��u�H�E�H���U����H�E�H���U����H�E�H���U�����E��H�E���]�UH��}�E�=�   ��   =�   A����   ����tl��t{���tl�=�   tm=�   -�   ��wg�Z=�   tS�\=U  =Q  }C-   ��wD�7= P  t0= P  -    ��w*�=   t�H�E�   �H�E�   ��E�H�H�E��	H�E�   �H�E�]�UH��AVAUATSH���  H�����H�����H�����H�� ���D������dH�%(   H�E�1�ǅ0���    H������ ����   ������t0�������   �¾��@ �    �    ����H������    �M�)�����0�����0�����������H��������  ��~H������ �¾�@ �   �    �T���H�� ����    ��  H������ <��   ������t0�������   �¾�@ �    �    ����H������     �>������H�������S�  ��~#H������ ���¾X�@ �   �    ����H�� ����    �F  H������ <��   ������t0�������   �¾��@ �    �    �k���H������     �^H������@��\�����\�����������H���������  ��~+H������ ����\����щ¾ȸ@ �   �    �����H�� ����    �  H������ <�;  H������@��4����6�  ��~/H�����H��� ����4����щ¾�@ �   �    ����������t-�������   �¾P�@ �    �    �f���ǅ0���   �(H�����H��� ��H������H�։��������0���H�������0������4����PH�� ������4���)vA��4���H�����H�JH�¾    H���������0���u
� D��H�����H��	� D��H�����H��� �Ћ�8���H��ATSASARAQAPWVQE��E��щ¾(�@ �   �    ����H��PH�����H��H������H������H������H�����H��H������H�������0�  H�������H�����H��� ����P���H������@��T���H�����H�� H��������P�����uaH�� ����    �n�  ��~�������¾��@ �   �    ������G�  ����   ��T����¾Ļ@ �   �    �������P�����u&H�����H��H��������T����PH�� �����N��P�����uCH�����H��H��������T����PH�� �������  ��~�ջ@ �   �    �/�����0����O  ��P������   ������H�����H�H��������������<�����T����� ��h���ǅl���    ��<���;�h�����   ��h��� �  v#��h���� �  �¾�@ �    �    �����8��h���+�<�����H������H�������H���������l�����l����<�����<���;�h���s~��h�����<����щ¾ �@ �    �    �-���ǅ0���   H�� ����    �A������ t8�������    �¾h�@ �    �    �����ǅ0���   H�� ����    ��0�����  H������H������H��P�����8���A��  ��������0�����0��� t'���  ��~��0����¾��@ �   �    �h���H�����H��H�������  ���q  H�� ���� ���_  H�� ���� ����p�����p�����  ��p����  �u�  ���$  H������H��� D��H������H��
� ��H������H��	� D��H������H��� D��H������H��� D��H������H��� D��H������H��� ��H������H��� ��H������H��� ��H������H��� D��H������H��� D��H������� �Ћ�T���H��ATSASARAQAPWVQE��E��щ¾�@ �   �    �����H��P�  �X�  ���  H������H��� D��H������H��� D��H������H��� ��H������H��� ��H������H��� ��H������H��� D��H������H��� D��H������� �Ћ�T���H��AQAPWVQE��E�Љщ¾@�@ �   �    �&���H��0�J���  ��~?H������H��� ��H������� �Ћ�T���A�ȉщ¾��@ �   �    �������0������������H�������X  H������ <�  ƅ.���������t!�������   �¾��@ �    �    �v���H������@��/����ђ  ��~&��.�����/����щ¾��@ �   �    �4���H������     H������ H��P���H������H��x���H��H���9���H��x�����H�����H����H������H��������H�����H����H���v���H��P�����H�����H����H���X���H�� ����    �0  H������
�@ H�U�H�����H��H���U���H�E�H��艳����H�� ������  H������   �b�@ H���������j  �E�    �E� H�����H�� ���ǅD���    H�U�H�� ���H��H���ߵ��H�������~H��������D���Hc�H��H��H�H��H�H�������P   H��H���~�����D���Hc�H��H��H�H��H�]�H�H-  �  H�E�H�ƿ    �f���H��������D���H������ t
�@ ���  ��~)H�����H��4�  H�E�H��� �@ �   �    �����H�U�H�����H��H���ʰ��H�E�H���������H�� �����[  H������   �(�@ H��腰������  �E�    �E� H�����H�����ǅH���    H�U�H�����H��H���T���H�������~H��������H���Hc�H��H��H�H��H�H�������P   H��H��������H���Hc�H��H��H�H��H�]�H�H-  �  H�E�H�ƿ    �۲��H��������H���H������ t
�@ ���  ��~8H�����H��4�  H�E�H���x�@ �   �    �����
�@ H�U�H�����H��H���خ��H�E�H��������H�� �����i
  H������   ���@ H��蓮������  ǅp���    ƅt��� H�����H�����ǅL���    H��p���H�����H��H���Y���H�������   H��������L���Hc�H��H��H�H��H�H�������P   H��H���������L���Hc�H��H��H�H��H�]�H�H-  �  H��p���H�ƿ    �ڰ��H��������L���H������ t
�@ �ц  ��~)H�����H��4�  H�E�H����@ �   �    �1���H�U�H�����H��H���
�@ ���  ��~)H�����H��4�  H�E�H����@ �   �    ����H�U�H�����H��H������H�E�H���&�����H�� �����  H������   �<�@ H��警������  �E�    �E� H�����H��H���ǅX���    H�U�H��H���H��H���|���H�������~H��������X���Hc�H��H��H�H��H�H�������P   H��H��������X���Hc�H��H��H�H��H�]�H�H-  �  H�E�H�ƿ    ����H��������X���H������ t
u&H������H��PH��辥��H�P�H�����Ƅ4�   H�E�f� 1
�@ �؀  ��~)H�����H��4�  H�E�H���P�@ �   �    �8���H�U�H�����H��H������H�E�H���H�����H�� �����   �r�  ��~H�����H�¾��@ �   �    �����H�E�H�0 unknowH�H�n_commanH�Xf�@d
�@ � �  ��~H�E�H�¾��@ �   �    ����H�U�H�����H��H���j���H�E�H��螤����H�� �����H�E�dH3%(   t螤��H�e�[A\A]A^]�UH��H�}��u�H�E�H���U����H�E�H���U����H�E�H���U�����E��H�E���]�UH��H��0H�}�H�u��U܉ȈE��E�   �E�    H�}� u���@ �    �    ����������\  H�E�H�xH�E��@��H�E�H�@�U�A��  ��H��H���,  ;E�t&��~  ��~� �@ �   �    �V����E������}� ��   �}� ��   �}� u\H�E��@��H�E�H�@�M�H�U�A��  H���H,  ;E���   �p~  ��~� �@ �   �    ������E������   �}�uUH�E��@��H�E�H�@�M�H�U�A��  H����+  ;E�tT�~  ��~�H�@ �   �    �����E������,��}  ��~�E؉¾p�@ �   �    �Y����E������E���UH��H�� H�}�H�u��U�H�}� u���@ �    �    ����������XH�E��@��H�E�H�@�M�H�U�A��  H���++  ;E�t&�W}  ��~���@ �   �    ������������    ��UH��H��H�}�H�E�H���    �    H��芢��H�E�H��;�    �    H���p������UH��H��0H�}�u�H�U�H�}� u���@ �    �    �M����������  H�E�H���y����E�H�E��@^f=K7t H�E��@^f=R7tH�E��@^f=H7�z  H�E��@�E�H�U�H��'��H�������U�H�E�H�p;H�E�Ѻ   H��������E��}� t�E��V  H�E��@;����H�E؈H�E��@;������<��H�E��@<��	Љ�H�E؈PH�E��@<��?��H�E؈PH�E��@ H�E��@ H�E��@ H�E��@>������H�E��@=��	Љ�H�E�f�P\H�E��@@������H�E��@?��	Љ�H�E�f�P^H�E��@^f=H7�i  H�E��@<v=H�E��@<w1H�E��@<t%H�E��@<t��@ �    �    �����   H�E��PH�E؈PH�E��@ �  H�E��@��E�H�U�H��'��H���/����U�H�E�H�p;H�E�Ѻ   H���Y����E��}� t�E���   H�E��P;H�E؈H�E��P<H�E؈PH�E��P=H�E؈PH�E��P>H�E؈PH�E��P?H�E؈PH�E��P@H�E؈PH�E��@ H�E��@ H�E��@D������H�E��@C��	Љ�H�E�f�P\H�E��@F������H�E��@E��	Љ�H�E�f�P^H�E��P\H�E�f�PH�E��P^H�E�f�P
�    ��UH��H��0H�}�H�u��U�H�}� u�P�@ �    �    �2���������   H�E�H���^���H�E��@��E�H�U�H��'��H�������H�E�H�p;H�E�   �   H��������E��}� uH�E��P;H�E���6y  ��~%H�E�� �ЋE��щ¾��@ �   �    蚾���E���UH��H�� H�}�u�H�}� u���@ �    �    �k���������vH�E�H������H�E��@�H�E��@!�E�H�U�H��'��H�������H�E�   �    �    H���"����E���x  ��~�E��¾��@ �   �    �����E���UH��H�� H�}�u�dH�%(   H�E�1�H�}� u��@ �    �    賽���������   �U�H�M�H�E�H��H���3����E�}� t�E��   ��w  ��~�E����¾>�@ �   �    �Z����E�<��   �U�H�E��H�������E��w  ��~�E�¾��@ �   �    �����}� t�E��D�U�H�M�H�E�H��H�������E�^w  ��~�E����¾>�@ �   �    �ʼ���E�H�M�dH3%(   t������UH��H�� H�}�u�H�}� u�`�@ �    �    臼��������vH�E�H������H�E��@�H�E��@�E�H�U�H��'��H������H�E�   �    �    H���>����E���v  ��~�E��¾��@ �   �    �
v  ��~�E����¾>�@ �   �    �v����E��u`�U�H�E��H�������E�}� t�E��D�U�H�M�H�E�H��H��������E��u  ��~�E����¾>�@ �   �    �����E�H�M�dH3%(   t�I�����UH��H�� H�}�u�H�}� u���@ �    �    �˺��������  H�E��@`<w H�E��@`<��   H�E��@a<��   �U�H�E��H���|����E��}� t�E��   H�E�H������H�E��@�H�E��@I�E�H�U�H��'��H������H�E�H�p;H�E�   �   H���.����E���t  ��~�E��¾�@ �   �    ������}� t�E��8�    �1�Wt  ��~!H�E��@a���¾8�@ �   �    迹���   ��UH��H��H�}�H�}� ��   H�E�H�@H��tz� t  ��~�p�@ �   �    �u���H�E�H�@�    H��袘����s  ��~H�E�H�@H�¾��@ �   �    �6���H�E�H�@H���ؘ��H�E�H�@    �    ��UH��H��@H�}�dH�%(   H�E�1�H�E�H�@H�E�H�E��P*H�E�f�P^�Hs  ��~H�E�H�@H�¾��@ �   �    貸��H�E�H�@�    H����  H�E�H�pH�E�H�HH�E�H�PH�E�H�@I��H�ƿ    �  �Eԃ}� t���@ �    �    �P����  H�U�H�Eؾ    H�������Eԃ}� �k  H�E��@^f=H7uCH�E��@^���E����E����E���A��A�ȉщ¾ �@ �   �    �ݷ����  H�E��@^f=K7tH�E��@^f=R7uCH�E��@^���E����E����E���A��A�ȉщ¾ �@ �   �    �~����  H�E��@^f=N7tH�E��@^f=T7uCH�E��@^���E����E����E���A��A�ȉщ¾H�@ �   �    �����?  H�E��@^f=S7tH�E��@^f=O7uXH�E��@^���E����E�D���E����E����E���VQE��A���щ¾h�@ �   �    诶��H����   H�E��@^f=V7tH�E��@^f=W7uUH�E��@^���E����E�D���E����E����E���VQE��A���щ¾��@ �   �    �;���H���ZH�E��@^���E����E����E�D���E�D���E����E���H��WVQ�щ¾��@ �   �    �ߵ��H�� �U�H�E؈P`�U�H�E؈Pa�    �KH�E��@`H�E��@a�p  ��~H�E�H�@H�¾��@ �   �    脵��H�E�H������������H�}�dH3<%(   t豔����UH��H�}�H�u�H�E�H�H�E�H�H�E�H�U�H�PH�E�H� H�U�H�PH�E�H�U�H��]�UH��H�}�H�u�H�E�H�U�H�H�E�H�PH�E�H�PH�E�H�@H�U�H�H�E�H�U�H�P�]�UH��H�}�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�E�H�     H�E�H�@    �]�UH��H��H�}�H�u�H�E�H� H�U�H�RH�PH�E�H�@H�U�H�H�H�U�H�E�H��H����������UH��H�� H�}���H�M�D�E�@�u�f�E��E����u��E����H�}�H�E�h�  QI��A���Ѻ   ��   H���+���H����UH��H�� H�}�H�u�H�E�� ���E��}�uP�E�    �?�E����Hc�H�E�H�� ���U��Hc�H�U�Hщ¾8�@ H�ϸ    �Ε���E��}�~��=�}�2u7�E�    �(�E�Hc�H�E�HЋU����Hc�H�U�H����E��}�~�H�E�H���  �    ��UH��H��@H�}�H�u�dH�%(   H�E�1�H�U�H�E�H��H��衔���E܃}� uP�E�    �/�E�f=�u!�U�E�H� H�E�H�� f9�u�   �R�E��E�H� H�E�H�� f��u��1�m  ��~&�E܉�裓��H�E܉��@�@ �   �    �e����    H�M�dH3%(   t螑����UH��H�� H�}�H�u��U�H�M��}�u-��l  ��~H�E�H�¾l�@ �   �    ����胿���S�}�u4�fl  ��~H�E�H�¾~�@ �   �    �Ա��H�E�H����   ��E�¾��@ �    �    譱���    ��UH��H�����` �6�����y
������   ����H�E�H�}� tg��k  ��~{H�E�H�HH�E��@��H�E��@��H�E��@��H�E�� ��H��QA��A���щ¾��@ �   �    ����H����{k  ��~���@ �   �    �����    ��UH��H��   H��x���dH�%(   H�E�1�H�U�H��x���H��H���d���H��x���� �@ H���}�����uUH�U�H��x���H��H���F����E���H�E�H�U��@   H���J���H�E�H���Ÿ��H�E�H�}� tH�E�H��褷���   H�M�dH3%(   t�~�����UH��H��   dH�%(   H�E�1�ƅ���� ǅ����    H��j  H������  H�����H�����H�����H�� ����<j  ��~*H�� ����P4H�� �����H�¾��@ �   �    蛯��H�� ����@9 H�� ���H�@H�@H����   ��i  ��~"H�� ���H�@H�¾ �@ �   �    �K�����i  ��~&H�� ���H�@H�@H�¾H�@ �   �    ����H�� ���H�@H�@H��赎��H�� ���H�@H�@    H�� ����@;H�����H� H�����H�������` �����H��i  H������H��H��茏���������i  ��~�������¾h�@ �   �    �}���ǅ����    �  H������������Hc�H��H�H� H��P���H��H������������������ tL��h  ����  ���������9���H�Ƌ�����������A�Љ�H���@ �   �    �����}  H������������Hc�H��H�H� � �@ H��������uI�(h  ���F  ��Z�������X����Ћ�����A�ȉщ¾��@ �   �    �x����  H������������Hc�H��H�H� H�� ���H��H���	��������������� �  ��`�����H�� ���H�U�A�@   H�Ѻ	  H�������H��p���H�E�H��H�������_g  ��~H��p���H�¾�@ �   �    �ʬ��H��p���H���̳�������?  �@   訍��H��(���H��(��� tw�h   荍��H��H��(���H�PH��(���H�@H��uj�8�@ �    �    �Y���H��(���H�@H��tH��(���H�@H���Ȋ��H��(���H��蹊��ƅ������8�@ �    �    �
���ƅ���������������<  H��(���H�H H��P����   H��H��行��H��(���H�@H������������Hc�H��H�H�H�H��p���H������H��H��(���H�PH��(���H�@H�� ���H�PH��(����@8 H��(����@9��e  ��~CH��(����@*��H��(����@(��H��(���H�@A�ȉ�H�¾h�@ �   �    �����|e  ��~7H��(���H�@H�PH��(���H�@H� H��H�¾��@ �   �    �Ϊ��H��(������` H�������O  �!e  ��~H��p���H�¾��@ �   �    茪��H�� ���H���/���ƅ���� �  ��d  ��~H��p���H�¾�@ �   �    �H���H��p���H��袲��H��(���H��(��� ��  ��d  ��~WH��(���H�@H�pH��(���H�@H�H��(����@*��H��(����@(��I��I�ȉщ¾@�@ �   �    �©��H��(����@9H��(���H�@H������������Hc�H��H�H�H�H��(���H�@H�� ���H�PH��(����@8 ��c  ����   H��(���H�@H�PH��(���H�@H� H��H�¾��@ �   �    �(����   H��p���H���}���H��(���H��(��� t7�oc  ��~UH��(����@4H��p���H�щ¾��@ �   �    �Ψ���)�8c  ��~H��p���H�¾��@ �   �    裨���c  ��~2��������證��H����������@ �   �    �l�������������������;����������H��P���H��P���H��P���H��X�����b  ��~!���` 菷��H�¾7�@ �   �    ����H��b  H�����H�����H� H������2  H�����H��0���H��0���H��8���H��8����@9����tS�b  ��~*H��8����P4H��8�����H�¾X�@ �   �    �~���H��8���H��P���H��H��������  H��8����@8������   H��8����@;������   ��a  ��~"H��8���H�@H�¾��@ �   �    �����sa  ��~7H��8���H�@H�PH��8���H�@H� H��H�¾��@ �   �    �Ŧ��H��8���H�@H�@H���`���H��8���H�@H�@    ��   H��8����@;����   H��8����@8��`  ��~&H��8���H�@H�@H�¾��@ �   �    �G�����`  ��~"H��8���H�@H�¾�@ �   �    ����H��8���H������������������� t.H��8���H�@H�@��������H�¾H�@ �    �    �Υ��H�����H�����H�����H� H�����H�������` �����H��P���H�����H�����H� H������   H�����H��@���H��@���H��H�����_  ��~.H��H���H�PH��H����@4H�щ¾��@ �   �    �%���H��H����@4���b���H��H���H���0���H��H���H�@H��脃��H��H���H���u���H�����H�����H�����H� H�����H��P���H9�����6����_  ��~!���` ����H�¾��@ �   �    脤��������H�M�dH3%(   t較����UH��H�� H�}�H�E�H�@H�PH�E�H�@H� H��H��������E��E����tm���
���t�   ���t1��tv�   �~^  ����   ���@ �   �    �����   �V^  ����   ��@ �   �    �ǣ���   �.^  ��~�H�@ �   �    裣���i�
��������E���UH��H���   dH�%(   H�E�1�ƅ��� ƅ��� �p]  ��~���@ �   �    ����H��]  H�� ���H��H��讃��������2]  ��~������¾��@ �   �    蟢��ǅ���    �f  H�� ��������Hc�H��H�H� H��P���H��H���������������� tL��\  ���  ��������[���H�Ƌ���������A�Љ�H���@ �   �    ������  H�� ��������Hc�H��H�H� � �@ H���������uI�J\  ����  ��Z�������X����Ћ����A�ȉщ¾��@ �   �    蚡���c  H�� ��������Hc�H��H�H� H��(���H��H���+������������� ��  ��`�����H��(���H�U�A�@   H�Ѻ	  H�������H��p���H�E�H��H���2�����[  ��~H��p���H�¾B�@ �   �    ����H��p���H������������  �@   �ʁ��H��8���H��8��� tw�h   证��H��H��8���H�PH��8���H�@H��uj�`�@ �    �    �{���H��8���H�@H��tH��8���H�@H����~��H��8���H����~��ƅ�����`�@ �    �    �,���ƅ�������������d  H��8���H�H H��P����   H��H���À��H��8���H�@H�� ��������Hc�H��H�H�H�H��p���H���<���H��H��8���H�PH��p���H����~��H��H��p���H��H���,�����H��8����P4��Y  ��~BH��8���H�HH��8����@*��H��8����@(��I�ȉщ¾��@ �   �    �/���H��8���H�@H��(���H�PH��8����@8 �zY  ��~7H��8���H�@H�PH��8���H�@H� H��H�¾��@ �   �    �̞��H��8������` H������ƅ����~�Y  ��~H��p���H�¾�@ �   �    膞��H��(���H���)~��ƅ��� �=��X  ��~2��������x��H���������@ �   �    �7�����������������;�������������� �  H�� ����    H�����H��X  H��0�����   H��0���H��@���H��@���H��H���H��H����@8������   �X  ��~"H��H���H�@H�¾K�@ �   �    腝����W  ��~7H��H���H�@H�PH��H���H�@H� H��H�¾h�@ �   �    �C���H��H���H�@H�@H����|��H��H���H�@H�@    H��0���H� H��0���H��0�����` ���������H�M�dH3%(   t�.|����UH���W  �ƿ    �}��H��W  H���G~���]�UH��H��0H�}؉u�dH�%(   H�E�1�H�E�    �E�����H�E�H����}��H�E���V  ��~ �U�H�E؉�H�¾��@ �   �    �J���H�U�H�E�H��H���|���E�}� u�E���H�U�H�E���H���8|���E��1�}V  ��~&�E���}��H�E�����@ �   �    ������}� ��   H�E�H����   H�E��@�ЋE�9�t�#V  ��~!H�E��@���¾�@ �   �    苛��H�E��@��H�E؉�H����|���E�}� t1��U  ��~&�E���v|��H�E���8�@ �   �    �8���H�E�H���.{���}� t$��U  ��~�E�¾`�@ �   �    �����E�H�M�dH3%(   t�=z����UH��H��`�}�H�u�H�U�H�M�L�E�dH�%(   H�E�1�H�E�H���5|��H�E�H�E��  H�E��  H�E��  H�U�H�E�    H���z���EЃ}� uP�}� xH�E��@��;E�k��T  ��~&H�E��@�ЋẺщ¾��@ �   �    �5����E������1��T  ��~&�EЉ��9{��H�EЉ����@ �   �    ������}� ��   H�E�H�@�U�Hc�H��H�H� H�E��E�    �   H�E�H�@�U�Hc�H��H�H�E�H�E��@������uWH�E��@��y&�}� uH�E��PH�E���<H�E��PH�E���,H�E��@��xH�E��PH�E����E�������E������E�H�E��@��;E��^����}� �3  ��S  ��~!H�E��@���¾�@ �   �    ����H�E��@��H�E���H���z���EЃ}� ��   �EЃ��t���tT���t*�n�#S  ����   �0�@ �   �    蔘���   ��R  ����   �h�@ �   �    �l����y��R  ��~q���@ �   �    �K����[��R  ��~S���@ �   �    �*�����<��R  ��~2�EЉ��4y��H�EЉ����@ �   �    ������
�������H�E�H����w���E�H�M�dH3%(   t�w����UH��H��0H�}��H�U؉M�D�EԈE�dH�%(   H�E�1��E�    D�E��u�H�}��M�H�U�H�E�E��I��H���x���E�}� ��   ��Q  ��~�E�¾�@ �   �    �=����}��u+��Q  ��~�0�@ �   �    �����E������   �}��u/�rQ  ����   �E��U��щ¾h�@ �   �    �ٖ���q�CQ  ��~&�E����w��H�E�����@ �   �    視���E������7�E�;E�}/�Q  ��~$�U��M��E�A�ȉщ¾��@ �   �    �f����E�H�M�dH3%(   t�u����f.�     D  AWAVA��AUATL�%L  UH�-L  SI��I��L)�H��H���gt��H��t 1��     L��L��D��A��H��H9�u�H��[]A\A]A^A_Ðf.�     ��  H��H���                         ctrl_handler %d Ctrl-C event    Could not set control handler : %d      The posix signal handler is installed   EXIT server     Entering non_blocking_accept_main ask_to_kill asked select failed. Error = %d   select failed. Error = %d (EINTR)       No connections/data in the last %ld seconds. ask_to_kill cancelled listening state : %d evaluate_auto_kill after listening accept error List of SockInfo %p     help version debug port auto-kill log_output                    �@             ��`            �@             ��`            ��@                    d       �@                    p       ��@                    a       �@                    l                                       hvd::l:p:a Parse param : %d --auto_exit  4 ***debug_level %s --log-output %s --log_output %s2 7184 ***port %s stlink-server
    --help       | -h	display this help
    --version    | -v	display STLinkserver version
 --port       | -p	set tcp listening port
       --debug      | -d	set debug level <0-5> (incremental, 0: Error, 1:Info, 2:Warning, 3:STlink, 4:Debug, 5:Usb)
   --auto-exit  | -a	exit() when there is no more client
  --log-output | -l	redirect log output to file <name>
   failed to convert address to string (code=%d) Remote address: %s        Entering create_listening_sockets()     Creating the list of sockets to listen for ... interface, tcp port : %s , %s default port : %s  getaddrinfo failed. Error = %d  getaddrinfo returned res = NULL getaddrinfo successful. Enumerating the returned addresses ...  Processing Address %p returned by getaddrinfo(%d) : %s  socket failed. Error = %d       Ignoring this address and continuing with the next.     Created socket with handle = %d 127.0.0.1       Error setting socket opts: %s, TCP_NODELAY
     Error setting socket opts: %s, SO_RCVBUF
       Error setting socket opts: %s, SO_SNDBUF
       stlinkserver already running, exit bind failed. Error = %s 
 Socket bound successfully listen failed. Error = %d Non Blocking Setting   Can't put socket into non-blocking mode. Error = %d alloc_sock_info failed.     Added socket to list of listening sockets       Freed the memory allocated for res by getaddrinfo       Exiting create_listening_sockets()      Entering destroy_listening_sockets()    prepare to close socket with handle %d Closed socket with handle %d     Exiting destroy_listening_sockets()     Entering process_accept_event() on socket %d, sock_info %p      ERROR: accept failed. Error = %d        Added accepted socket %d to list of sockets     Previously recd data not yet fully sent.        recv got WSAEWOULDBLOCK. Will retry recv later ...      ERROR: recv failed. error = %d  recv returned 0. Remote side has closed gracefully. Good.       get_stlink_tcp_cmd_data: recv timeout. error = %d       get_stlink_tcp_cmd_data: recv failed. error = %d        get_stlink_tcp_cmd_data: recv returned 0 write cmd. Unexpected client socket closed     get_stlink_tcp_cmd_data: select timeout (no error)      get_stlink_tcp_cmd_data: select timeout. error = %d     get_stlink_tcp_cmd_data: select failed. error = %d No data pending to be sent.  send got WSAEWOULDBLOCK. Will retry send later ...      ERROR: send failed. error = %d  Sent %d bytes. Remaining = %d bytes.                    Error:  Info :  Warn :  Stlk :  Debug:  Usb  :                   �@     �@     �@     �@      �@     (�@     %s%d %d :  w    . - Server version %d %d %d 
   ERROR: Server version not set (too high) ERROR: Server version not set  stlink-server v%lu.%lu.%lu (2021-06-09-12:03) 
 7184 stlink-tcp initalization Cannot install signal handler create_listening_sockets    libusb_init(): Cannot initialize libusb non_blocking_accept_main destroy_listening_sockets libusb_mgt_exit_lib  Delete stlink next %p, list previous %p get_stlink_by_key 0x%x to find, usb device ptr %p, usb_key 0x%x usb not found : 0x%x    get_stlink_by_serial_name usb instance %p, key %x usb not found : 0x%lx Get_device_info (index: %d) return usb device ptr %p    Get_device_info usb found 0x%x, (PID 0x%x, serial %s)   Get_device_info, Usb device NOT found (device index: %d)        stlink_open_device 0x%x (usb) with 0x%x (psock_info)    stlink_open_device: libusb_open of libusb dev %p return %d and libusb handle %p Opened device usb_key 0x%x Opened device ERROR : %d     stlink_open_device: libusb_open device failure 0x%x     stlink_open_device: Error in association creation       stlink_open_device: libusb handle %p already opened     stlink_open_device: Error unkown device 0x%x assoc null stlink_close: close_connection(assoc_id 0x%x)   STlink device has been disconnected, need to close (assoc 0x%x) unknown assoc : 0x%x    alloc_init_sock_info: malloc returned NULL.     alloc_init_sock_info : Allocated %p Freed sock_info at %p       Delete SockInfo next %p, list previous %p       Refresh: Opened assoc cookie_id 0x%x (for usb_key 0x%x) becomes invalid add to list assoc of usb device ptr %p, sock_info ptr %p        Malloc error: %p, sock_info %p not added to assoc list New stlink sock_info key 0x%x    New stlink assoc key 0x%x (ptr %p) Reuse a stlink assoc key 0x%x not ask to exit() because %d   close_connection : assoc cookie_id 0x%x close_connection : usb to find  0x%x, connection_count %d       close_connection : assoc key 0x%x found as the last user of stlink (assoc ptr %p)       close_connection : libusb_close %s last tcp client : %d close_connection : No Stlink USB close, device already disconnected previously  TCPCMD REFRESH_DEVICE_LIST : unexpected TCP cmd size %d instead of %d   TCPCMD REFRESH_DEVICE_LIST : return %d  TCPCMD GET_NB_DEV : unexpected TCP cmd size %d instead of %d    TCPCMD GET_NB_DEV : %d device(s)        TCPCMD GET_NB_OF_DEV_CLIENTS : unexpected TCP cmd size %d instead of %d TCPCMD GET_NB_OF_DEV_CLIENTS : %d client(s) for stlink_usb_id 0x%x      TCPCMD GET_DEV_INFO : for device index %d (info size %d)        TCPCMD GET_DEV_INFO : unexpected TCP cmd size %d instead of %d  TCPCMD OPEN_DEV : unexpected TCP cmd size %d instead of %d      TCPCMD OPEN_DEV for stlink_usb_id : 0x%x, access: %d (sock info 0x%x)   TCPCMD OPEN_DEV FAIL, internal assoc not key created    OPEN success, created cookie_id: 0x%x   TCPCMD CLOSE_DEV : unexpected TCP cmd size %d instead of %d     TCPCMD CLOSE_DEV for cookie_id: 0x%x    TCPCMD SEND_USB_CMD : unexpected TCP cmd size %d instead of %d minimum  TCPCMD SEND_USB_CMD : cookie_id 0x%x, CMD : 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x %02x, %02x, %02x, %02x    REQUEST_WRITE : 0x%x bytes received Write 0x%x bytes REQUEST_READ TRACE Cmd data size %d larger than max supported size %d      TCPCMD SEND_USB_CMD : unexpected TCP cmd+data size %d instead of %d     TCPCMD SEND_USB_CMD : unexpected TCP cmd size %d instead of %d  TCPCMD SEND_USB_CMD : stlink_send_command error %d      ANS (0x%x bytes): 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x ... ANS (0x%x bytes): 0x %02x, %02x, %02x, %02x, %02x, %02x, %02x, %02x     ANS (0x%x bytes): 0x %02x, %02x TCPCMD GET_SERVER_API_VERSION : unexpected TCP cmd size %d instead of %d        TCPCMD GET_SERVER_API_VERSION cmd, client API v=%x server API v=%x get-nb-stlink        get-nb-stlink : command received from (%s) 1 %d
        get-nb-stlink: (%s) : returned value '%s' get-stlink-descriptor get-stlink-descriptor : command received from (%s) 1 %x %x %x %s
       get-stlink-descriptor : (%s): returned value : %s serial code %s usb not found %d open-device %x        open-device : commmand received from (%s) : 0x%x, 0x%x  process open-device (%s): cookie_id = 0x%x      process open-device (%s): error open-device : (%s): returned value "%s" close-device %d close-device : commmand received from (%s) : cookie_id = 0x%x   close-device (%s): returned value %s stlink-tcp-version stlink_tcp_version assoc %p     stlink-tcp-version : command received from (%s) 1 %d %s %d %d %d %x %x
 stlink-tcp-version : (%s) returned value '%s' usb-refresh       usb-refresh : command received from (%s)        usb-refresh : (%s) returned value '%s' stlink-blink-led stlink-blink-led : command received from (%s)   Index %d is stlink_usb key 0x%x stlink-blink-led : (%s) returned value '%s' register-client     register-client : (%s) returned value '%s'      TCPCMD : unknown command received %s    process_stlink_tcp_cmd : returned value %s      send_cmd: Internal error NULL stlk_dev* STlink cmd send on USB failed   STlink cmd data send on USB failed      STlink cmd data read on USB failed      STlink cmd unexpected request type %d   read_trace_data: Internal error NULL stlk_dev* STlink read trace data failed    get_version: Internal error NULL stlk_dev*      Nucleo STM8 detected, not supported by stlinkserver     get_current_mode: Internal error NULL stlk_dev* STLink GET_CURRENT_MODE cmd sent (status %d): mode %d   jtag_exit: Internal error NULL stlk_dev*        STLink JTAG_EXIT cmd sent (status %d)   exit_jtag_mode: Internal error NULL stlk_dev* STLink current mode: 0x%02X       dfu_exit: Internal error NULL stlk_dev* STLink DFU_EXIT cmd sent (status %d)    exit_dfu_mode: Internal error NULL stlk_dev*    blink_led: Internal error NULL stlk_dev*        STLink BLINK_LED cmd sent (status %d)   no execution because the jtag version %d is too low     libusb_release_interface debug libusb_close %p  stlink_mgt_open_usb_dbg_if : for libusb dev_handle = %p libusb_mgt_claim_interface failed       STLINKV2 v%dJ%dS%d, PID 0x%04X  STLINKV2-1 v%dJ%dM%d, PID 0x%04X        STLINKV3 v%dJ%dM%d, PID 0x%04X  STLINKV3 v%dJ%dM%dB%dS%d, PID 0x%04X    STLINKPWR v%dJ%dM%dB%dP%d, PID 0x%04X   new STLINK v%dJ%dM%dB%dS%dP%d, PID 0x%04X       Usb open debug interface Error: libusb_close %s         D7H7J7K7N7O7R7S7T7V7W7  %02hX   Error libusb_get_device_descriptor (%s, %d) plug event dev %p unplug event dev %p Unhandled event %d    libusb_init, libusb version : %d.%d.%d.%d : %s Error libusb_get_version Refresh list, usb instance %p, usb_key 0x%x     Refresh: libusb_close before refresh %s libusb_close libusb_handle %p   Refresh: libusb_get_device_list found %d device Refresh: Error libusb_get_device_descriptor (%s, %d) for device %d      device %d (VID 0x%04X, PID 0x%04X) is not an STLink     Refresh: libusb_open success %s Refresh: Malloc error new stlink NOT added      Refresh: Add device %s to USB list: VID 0x%04X, PID 0x%04X      new libusb_device = %p, libusb_handle = %p      Refresh: Malloc error libusb_close STLink %s    Refresh: keep stlink device unchanged in device list %s Found VID 0x%04X, PID 0x%04X, libusb_device = %p, libusb_handle = %p    Updated libusb_device = %p, libusb_handle = %p  Refresh : unusable stlink device, key 0x%x for serial %s        Refresh : unusable stlink device %s Error libusb_open (%s, %d) count stlink_usb_list :%ld       move usb device to usb_delete_list %p, usb_key 0x%x     Refresh: libusb_close usb Device %s     close usb libusb_device = %p, libusb_handle = %p        usb already opened. libusb_handle %p    Refresh: keep libub_open after refresh %s       Refresh: Unable to claim interface again for libusb_handle %p, error %d Refresh: remove from USB list usb_key 0x%x, %s Refresh: List USB :%ld   libusb_open Error: Memory allocation failure    libusb_open Error: The user has insufficient permissions        libusb_open Error: The device has been disconnected     libusb_open OK, libusb dev_handle %p libusb_open Error (%s, %d) libusb_get_device_list entry    libusb_get_device_list found %d device  Error libusb_get_device_descriptor (%s, %d) for device %d libusb_open success %s        Init refresh : Malloc error new stlink NOT added        Add to stlink USB list: VID 0x%04X, PID 0x%04X, serial %s       Init refresh : new libusb_device = %p, libusb_handle = %p       Init refresh : Malloc error libusb_close STLink %s libusb_close USB device %s   libusb_close USB libusb_device %p, libusb_handle %p     libusb_get_configuration for dev_handle = %p, configuration = %d        Error libusb_get_config_descriptor (%s, %d) libusb_set_configuration : %d       Error libusb_set_configuration (%s, %d) libusb_mgt_set_configuration : return %d        libusb_mgt_claim_interface : interface %d > bNumInterfaces %d   Error libusb_get_config_descriptor (%s, %d) in claim interface libusb_claim_interface %d        libusb_claim_interface error LIBUSB_ERROR_NOT_FOUND     libusb_claim_interface error LIBUSB_ERROR_BUSY  libusb_claim_interface error LIBUSB_NO_DEVICE libusb_claim_interface error      Error libusb_claim_interface (%s, %d)   libusb_bulk_transfer: Error %d  libusb_bulk_transfer: Error USB device disconnected     libusb_bulk_transfer: Error timeout, transferred %d/%d bytes    libusb_bulk_transfer: Error (%s, %d)    libusb_bulk_transfer: No error (%d) but transferred %d/%d bytes ;  `   `B��X  �F��(  �G���  H���  �H���  �H���  JI��   �I��   �N��@  �Q��`  �Q���  R���  &R���  �R���  �X��   �Y��   �[��@  =]��`  �`���  Ib���  �b���  �c���  �e��   �e��   f��@  kh��`  �h���  ;j���  �j���  �j���  =k��   �k��   Gl��@  m��`  sm���  �m���  �n���  �n���  _q��   kq��   xq��@  �q��`  Qs���  �s���  �s���  �s���  �t�� 	  �t�� 	  ;u��@	  �u��`	  �u���	  ,v���	  �v���	  �v���	  w�� 
  �w�� 
  Ly��@
  �y��`
  y{���
  �{���
  .|���
  �|���
  �|��   �}��   ����H  ���h  �����   ����  c����  ~����  I���  ���(  -���H  ֧��h  ����  &����  ˪���  �����  Į��
   ���K    A�C
  +���`    A�C
  k����    A�C
  
  ģ���    A�C
  H����    A�C
  ����    A�C
  �����   A�C
@            �@     
       4                                           �`            `                           �@            �@            H       	              ���o    0@     ���o           ���o    �@                                                                                                             ��`                     �@     �@     �@     �@     �@     �@     �@     �@     @     @     &@     6@     F@     V@     f@     v@     �@     �@     �@     �@     �@     �@     �@     �@     @     @     &@     6@     F@     V@     f@     v@     �@     �@     �@     �@     �@     �@     �@     �@     @     @     &@     6@     F@     V@     f@     v@     �@     �@     �@     �@     �@     �@     �@     �@     @     @     &@     6@     F@     V@     f@     v@     �@     �@     �@     �@                             P�`     P�`                                   ��`     ��`     ��`     ��`     GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.11) 5.4.0 20160609 ,             �@                            ,    �       �@     �                      ,    �       �"@                           ,    �       �%@     �                      ,    �#       Y6@     �                      ,    B)       *:@     !                      ,    %,       K>@     S	                      ,    �7       �G@     �                      ,    9>       KI@     X                      ,    �I       �P@     "                      ,    �W       �r@     �                      ,    �d       ��@                           �       �   �      �@                �  �  A  �  �  5   int h     }B   U   �W   ?       �^   �  ��   c  �     -   �   	{    �  �   �  c   
�   7�   �   9W    �   :W    �   �   
   �l   W   
  	{    �>C  �  @W    8  AW   �  CW   �  ��   i  �
  �  UY  _  j  W    �  �   N  H   !�   �  W   �  �    C  �  
K   ��  �  #j   �  +�   v  .W   ��  1�  � �  �  �  W   /<    ~5  �   i  s      &  �   S  E�@     V       ��  sig EW   �l�  E�  �`  E�   �X K  d�  @     �       ��  act f�  ��~rc gW   ��~ �  FW    �   m  �   �     �@     �        �  �8   �  �  A  �  �  5   int h   ?   +	  �i   �  �i   �   �  �  �   �   w    G  !�    �  6i   	�@�   �  E�     
�   �   p    $  K�   �  c   �   7/  �   9b    �   :b    
  /  4	  F   �  	�j  l  	�:   �	  	�j   
�   z  p   
�  �  
�:   c  
��    
��  �  
��   �    ,  
�[  �  
 :   �  
�  �  
�  �  
P  �  
�   
?   �  p    �	  0?     1F   O  3M   �  
�    
�  �  
!�    k  
w�  
�   �  
�   n  
�0  _  
�@   
�  0  p    
�  @  p    
�  P  p    �  
�i  �  
��    �  Lb   �	  �  o
�   �  p   � �  l  h�
�   �  p   1   ��    ��    �	  ��   �  ��    �  b   /�    ~5  �   i  s      &  �   X  (*H  �  +t   m  ,H  �  .�  �  /�   key 0M   $ �  �  @+�  �  ,t   1  -�	  �	  .�   Z  /�   key 0M   4�  1�  8�  2�  9e  3�  :D  4�  ; N  �  ��  @	  ��   O  ��  �  ��  �  ��  �  ��  v  ��  4  ��  
  �  �  �  
F  �  
�  ;  
�  �M   t   ��  a  �b   `  �b   �  �     ��   (  ��  0�  �b   8D  ��  < �  ?   
�  
�  �	  p     �  ��  �@            ��	  !�	  ��	  �h 
  t  "  >H  �@     \       ��
  #nth >M   �L$�  @�  �P$�  A8   �X%@     $       $�	  DH  �h%@            $	  D�	  �`   &�  QZ@     <       �'�  a�@           �c  $#  cc  ��~$  e�   ��~$  g�   ��~$+  hb   ��~$�  i�  ��}$�  jb   ��~$�  kb   ��~(err lb   ��~$�  m�  ��})�  s�@     %�@     �      $�  }�  ��~*@     (       �  $�  b   ��~$�  b   ��~ *J@     x       �  $�	  �H  ��~%J@            $	  ��	  ��~  %� @     �      $�	  �H  ��~*� @            >  $	  ��	  ��~ %�!@     �       +�  h  ��~    i   �  ,  8�  	 �`     -�  Fb   -  6b   ,  :�  	��`     .�  ,P  <t  	P�`      ]   �  �   v
     �"@           �  �  �  A  �  �  5   int h   ?   r   �     r   �  c   �   7�   �   9W    �   :W    �   �   	4	  ;   �  ��   l  ��    �	  ��    
r     e   
4   .  e    W   	�	  04   	  1;   	O  3B   	�  J    y  �  !U    	k  w?  ծ  �  ׮  n  پ  _  ��   
4  �  e    
?  �  e    
J  �  e    �  ��  �  ܄    l   �  �  W   /K    ~5  �   i  s      &  �   D
   h�    jy    K
  mW   2
  n.  val oW    
  >W   �"@           ��  S
  >W   �\X
  >�  �Pc @W   �d    �
  DW   �`  l
  .W   	��`     *
  /W   	��`     
      e    K  7
  4:  	 �@       
  9l   �  FW   ]
  1�   �     �   E     �%@     �      �  �  A  �  �  �  5   int h   ?   +	  �^   �  �^   �   �  �
  1  e    $  K  �  c   �   7o  �   9W    �   :W    J  o  
2     2    4	  	4   �  
��  l  
��   �	  
��   
�     e   
�6    
��   N  
�6  $  
�B   x 
�   F  e   u �  F  	  Q  V  �  a  f  �  q  v  	  �  �  j	  ��  �  ��   c  �a    �  �  �b   �  �  ,  �'  �   �   �  a  �  �  �  �  �  �   �  '  7  2  7  {  B  G  �  R  W  (  b  g  �  r  w  T  �  �  �  �  �  �  Q  �  �  a  �  �  q  �  �  �  �  �  �  �  �  �  �    2      B    (  R  "  8  b  2  H  r  B  X  �  R  
-   r  e    �	  0-     14   O  3;   �  �    �  �  !�    ;   )a  �   �
  3�
  \
  g�  lK
r  �  e    
}  �  e    
�  �  e    �  ��  �  �l      0
  
  
�   �  e   � �  l  h�9T  f  :�      <[  �  =�    ?|  �	  @W   $�H	  AW   (��	  B�  ,�key C;   0��  DT  4� 
�   d  e   1   ��    ��    �	  ��   �  ��    
�   �  e   - $�  g�  �&@           ��	  "  i�  ��#res jU  ��"�  kU  ��"M  l[  ��~"?  m�	  ��#i nW   ��~"�
  oB   ��#ret p�  ��~#err qW   ��~%�   m,@     &t(@     �      "�  ��  �P"�  �4   ��~"2
  �W   ��~"�  �W   ��~#a �W   ��~  �  '�  1�,@           �[
  (�  6�   �P)tmp 6�   �X&-@     �       (�	  8�	  �h&-@            (	  8[
  �`   a
  �   *�
  K�	  �-@           ��
  +t
  NW   ��~(M  O[  ��~(?  P�	  ��~(�
  QB   ��~)err RW   ��~ *�
  ��  �/@     U      �X  +t
�  (
�  �#  �y  n
  �  A  �  �  �  5   int h   ?   r   �  c   �  �   7�   �   9W    �   :W    �   �   �  U�   �   	�   
W    l   �    �    �r    �	  �l   �  �l    �  W   /X    ~5  
  }W   �\X
  }�   �Pret W   �l   4�   	 �`     �  FW    �   r
  �   o     K>@     S	      3  �  �8   �  int �  �  A  �  5   h   ?      �  c   �     �   p    	�   7�   
�   9?    
�   :?    �   �   �	  0M     1T   O  3F   �  L?   	�	  %  
o
�  %      
f  :    
  <�   
�  =}  
  ?+  �	  @?   $�H	  A?   (��	  B}  ,�key CF   0��  D  4�      p   1 		  `8  
�  cF    
�  fF    	\  )m�  
|  pF    
�  v�   
M  yT   $
G  |T   &
*  �M   ( 	X  (	*�  
�  	+    
m  	,�  
�  	.I  
�  	/}   
+I  
�  
,    
1  
-,  
�	  
.y   
Z  
/O   
0F   4
�  
1}  8
�  
2}  9
e  
3}  :
D  
4}  ; �  �  �  @	  ��    O  ��   �  ��   �  ��   �  ��   v  ��   4  ��   
  �   �  �   
F  �   
�   ;  
�  �F   t   �)  a  �?   `  �?   �  ��     �w   (  �z  0�  �?   8D  ��  <   M   e  �  p    	�  h:,  
�  <8  
	  =�  
�  >�   
�  ?�   
�  @�   
�	  A>  
$  B>  ;
:  E�   `
�	  F�   a �    $  �   N  p    �  ?   
  C@     n      �=
  �  �F   �Lt
  �`'0   !ret �?   �\  �  (�  �oE@            �&�  �8   {E@     
  �8   �E@     �       ��
  �  �F   �\ _  �=
  �h )3  8   	F@     X      �U  *�  F   �L*�  U  �@+cmd z  ��*  z  ��*R  8   ��,_  	=
  �`,1  ,  �h-ret 
e   
e    �	  0-     14   O  3;   �  ^    �  �  !i    k  wS  ��  �  ��  n  ��  _  ��   	H  �  
e    	S  �  
e    	^  �  
e    �  �  �  ܘ    �  LW   
e   1 �  W   
/E    ~5  �   i  s      &  �   �  d�G@     G       �q  �  d�   �h :  1;   �G@            �g  <�  �G@     �       ��  ?  >�  �h o  w  Y�H@     B       ��  t
FW   P  -s   �  /;   	��`      i   �  �   �     KI@     X      �  �  �8   �  �  A  �  �  5   int h   ?      �  c   �  �   7�   �   9b    �   :b    �   	�   �	  0?     1F   �  Lb   �	  
  o
   �  
   �   

l  h�9�  f  :�      <�   �  =b    ?  �	  @b   $�H	  Ab   (��	  Bb  ,�key CM   0��  D�  4� 
�  	�M   t   	�H  a  	�b   `  	�b   �  	��     	�w   (  	��  0�  	�b   8D  	��  < �  
  	�   �  	�   
F  	�   
�   ;  	
+j  �  
,�    1  
-j  �	  
.y   Z  
/x   key 
0M   4�  
1b  8�  
2b  9e  
3b  :D  
4b  ; �  X  (*�  �  +�    m  ,�  �  .�  �  /b   key 0M   $ i  �  �  b   /    ~5  �   i  s      &  �   $  SKI@     E       �F  �  S
  �hV  S
  �` �  d�I@     G       �r  �  d
  �h �  =M   �I@     e       ��  <  =b   �L�  ?
  �X�  @M   �T �I@     0       �	  C�  �h �I@            	  C  �`   p  
  !�   "�  K<J@     �       ��  <  Kb   �L�  M
  �X TJ@     a       �	  O�  �h TJ@            	  O  �`   D  WM   �J@     6       ��  �  Y
  �h�  ZM   �d #�  bM   K@            �$�  g�  K@     �       �.  �  g�  �Xt
  �X&L@            �  	  �  �`  �L@     �       �  ��  �h  $i  �b  \M@     X       �	  �  �b   �l $�  �b   �M@     �      ��	  �  �M   �L_  ��  �` N@           |  �b   �\ \N@     �       �  ��  �h   �  ��  �O@     R       �
    �M   �L�  �
  �X �O@     "       _  ��  �h �O@            	  �  �`   %  ��  �O@     c       ��
  t
  �X �O@     2       �	  ��  �h �O@            	  �  �`     �M   >P@     e       �  <  �M   �L�  �
  �X�  �M   �T YP@     0       �	  ��  �h YP@            	  �  �`   '�  Fb   '  2b  (]
  3=  	��`     )b  (  :M   	p�`     (�  ;�   	��`      Q   0  �   �     �P@     "      �  �  �  A  �  �  5   int h   ?   t   �  �   t   c   �  t   �   e    t   �   e    	�  W   /�   
  ~
5  �   i  s      &  �   �   7   
+�  
,L   
-x  
.n   
/�   key 
0B   4
1�  8
2�  9
3�  :
4�  ;   �  �_  @	  �+   O  �+  �  �6  �  �+  �  �+  v  �+  4  �+  
  6  �  6  
F  6  
+  ;  
�  �B   t   �u  a  �W   `  �W   �  ��     �l   (  ��  0�  �W   8D  ��  < d  4   �  �  e    �  h
 _  p  +    e    �  *�P@     I       �Y  buf *Y  �hval *W   �d +  �  BB   �P@     �       ��   )  BW   �\!�  D-   �h ",  s�Q@     �       ��
  %a  �t   ��x%�  �t   ��x%�  �-   ��x%�  �-   ��x%�  �-   ��z $Qa@     Q      �
  %  ��  ��z%o  �   ��{%M  �&  ��~%  �{   ��y&i �W   ��x%�  �n   ��y&key �B   ��x $�c@     e      c  %o  �   ��{%M  �+  ��~%  �{   ��y&i �W   ��x%�  �n   ��y%�  �W   ��z%_  ��
�
t   �   e   
  (      �  %  *  T  5  :  K  �   E  [    U  k    e  {  $  u  �  4  �  �  D  �  �  �  �  �  �  �  �  �  �  �    �  �    �  �  %  �    5    
4   %  e    	�	  04   	  1;   	O  3B   	�  ;    j  �  !F    	k  w0  ՟  �  ן  n  ٯ  _  ڿ   
%  �  e    
0  �  e    
;  �  e    �  ��  �  �u    �	  
  	0  

%  

0  Z  e    �  @
+�  �  
,�   1  
-p  �	  
.n   Z  
/   key 
0B   4�  
1  8�  
2  9e  
3  :D  
4  ; �  h:p  dev ;�   �  <  	  =�  �  >%  �  ?%  �  @%  �	  A  $  B  ;vid C0  \pid D0  ^:  E%  `�	  F%  a �  O  -�  =  .%   Z  /%  �	  0%  R  1%  x  2%  �  3%  F  4%  �  5%  M  60  G  70  
 �  �  
%    e    �  W   /^    ~5  �   i  s      &  �   �  *�r@     I       ��  buf *�  �hval *W   �d %  c  WW   �r@     �      �	  1  Wp  �Xbuf W	  �P�  WW   �L�  W%  �H�  YW   �l res ZW   �h 	  %  �  �W   �t@     �       �k	  1  �p  �hbuf �	  �`�  �W   �\ !d  �0u@     C       ��	  1  �p  �h �  �W   su@           ��	  1  �p  �Xkey �B   �T�  ��	  �H res �W   �l�  �%  �k v  w  �W   �x@     �       �_
  1  �p  �X6  �  �Pkey �B   �L res �W   �l O  �W   Yy@     �       ��
  1  �p  �Xkey �B   �T res �W   �l "!  W   z@     ;      �
  #1  p  �X$key B   �T%res W   �d&6  %  �c ";  -W   ={@     �       �Z  #1  -p  �X$key -B   �T%res /W   �l "  BW   �{@           ��  #1  Bp  �X$key BB   �T%res DW   �d&6  E%  �c "�  _W   �|@     =      �	  #1  _p  �X$key _B   �T&�  aW   �l "�  �W   6~@     �       �;  #1  �p  �h "�  �W   �~@     �      ��  #�  ��  ��%err �W   �D&1  �p  �H'�  �@�@     &�  �v  �P Z  (�  FW    �   q  �        ��@              �  �8   �  �  A  �  �  5   int h   ?      �  �      �  c   �   7�   	�   9b    	�   :b    �   
�   4	  F   �  ��   	l  ��    	�	  ��         p   
  
  
/  
?  
O  j	  �  	�  ��    	c  �  	  �l  	�  �+   Z  
�  ,  ��  �   �    �  �  �  V  �  �  �  V   �  
�  
   
  
   
0  
@  
P  a  �   
[  q    
k  �  *  
{  �  :  
�  �  J  
�  �  Z  
�  �  �  
�  �  �  
�  �    
�  �    
�    +  
�    ;  
  !  K  
  ?   ;  p    F   �	  	0?     	1F   O  	3M   �  V    �  	�  !a    k  wK  պ  �  ׺  n  ��  _  ��   @  �  p    K  �  p    V  �  p    �  �  	�  ܐ    �	  (  	o
:�  dev 
;�   	�  
<�  		  
=�  	�  
>@  	�  
?@  	�  
@@  	�	  
A�  	$  
B�  ;vid 
CK  \pid 
DK  ^	:  
E@  `	�	  
F@  a 
�  �M   t   ��
  a  �b   `  �b   �  �     �w   (  �*  0�  �b   8D  �0  < �  @  �  p    )  M      �  �  #  -  �  �  R  n  !�  "�  #[  )�  *`  0 �  M   F3  �  �|    ;  M   Tc     �  F  �  �   �  M   g�  �        u  �  �  �  i  	  
�  �  �  0�  1 �  ��  @	  �@   O  �@  �  �K  �  �@  �  �@  v  �@  4  �@  
  K  �  K  
F  K  
@  ;  
  �  �
   �  �
  �  �
  [  �
  rc ��   �  ��    K    �
  
  �   >   �  ~�  }�  |$  {�  z  y�  x�   w4  vN   u�  t�  � S	  M   R�
  a   %  �  v	  z  �  �   �  �  a  �M    `  �M   t   ��
   9  �    $  �   #
  ?   �
  ?  p    
  <  qb   M   �k  b   �    +  �Q  �  @+�  	�  ,   	1  -�  	�	  .y   	Z  /�   key 0M   4	�  1.  8	�  2.  9	e  3.  :	D  4.  ; 5  �  b   /=    ~5  �   i  s      &  �   w     @��@     C       �}  �  @(  �hV  @(  �` $  SԂ@     E       ��  �  S(  �hV  S(  �` �  d�@     G       ��  �  d(  �h �  t`�@     K       �
  "�  tb   ��@     �       ��  #ctx t�  �h#dev t�  �`�
  uk  �\  uw   �P 
  "%  �b   H�@     �       ��  $v ��  �h �  �	  "Y  �.  �@     �       �{  #dev ��  ��~&�  ��  ��~&Z  ��  ��&�  �{  ��'T�@     U       &�  �=  ��~     �  p   ? "�  �b   ć@     �      ��  $cnt �b   ��}$err �b   ��}&@  �.  ��}&�  �{  ��~$idx �b   ��}&�  �b   ��}&A  ğ  ��}&   �=  ��~&�  ��  ��}&�  �(  ��}&�  �(  ��~(�  7  ��~)�@           �  &�  �=  ��~'�@            &	  ϥ  ��~  )��@           �  &Z  ��  ��~'��@           &M  �{  ��  )
�@     �       (�  �=  ��~'
�@            (	  ��  ��~    ,�  ��@     (       �+�  �b   <�@     �      ��  !�  �$  �H!�  �b   �D(g  ��  �`*ret �b   �T(�  ��  �X(�  �b   �P 
	  +�  
:;   I  7 I  
I  ! I/  7 I  
 :;  *  +4 :;I  ,4 :;I?  -4 :;I?<  .5 I   %  $ >  $ >   I  & I  :;  
I  ! I/   <  
I  ! I/  7 I  
 :;  &  '.?:;'@�B  (4 :;I  )4 :;I  *.?:;'I@�B  + :;I  ,4 :;I?<  -4 :;I?   %   :;I  $ >  $ >      I  :;  
 :;  I  ! I/  
 I  I:;  ( 

! I/   <  
:;  
( 
I  ! I/   <  
 :;  (4 :;I?<   %   :;I  $ >  $ >      I  & I  :;  	
7 I  I  ! I/  
֟ �=	< 栭�� �*	+�ɑ���'����=��= �� u�|�O� �<�#g�h �=�g�hg=i��=-iK5��y�����Y(U6ʹ%�ɟ ����u� ��r]� ����=��>�u� �=�ɒu� ��� ��Gt �= gX�Q  � ���=�g�g=�����ׯ�� �%K Y   �   �
X ���q�X �����i�Xu �Z �% ��^�$ K1LY@Lu1��u�? ���6��v t��s� t���u�>����)=.�� � W ��K Y   �   �
.5� ���u �����|X!���� �#���|X"����u �+���|X(� �/��	�(�#��ˢ�#�|X! ����
��� �5ʟ=�0 ��j����}X"��� ��ʡu���}X(�����"� ��!�"[h�"�� �� �ɮ!=�!! �@��g��"�#,��$�����.� ��# �!"�� �� �� � ? �t�~X"w�� � & � � � � � � ���~X� �$� �)Y�f�~X� B ~ �� �$,�q>r0 �) �$ �) � Y �f�~X� B ~ ��' �:� �." �$� � ) Y � f�X� B ~ ��' �*/�� �+ 	� 	Y 	� f�X� N � ��'> � .u �� �$.[ �  �� ���K�=s=sKsl3.� � ) Y 5fMX� B ~ �� �$�� � ) Y )fYX� B ~ ��' �$> �� �(#�� � 
<����D�0!��	<�/"/�
t�/� �*�u �" �&g/ v� � ���2� � 8Z+ � 5[2�+Y ����u�=�0�=v!"(�Y�� �C �7� ��� ��Y� �W�(Y� �<Y� �, �� ��.@ v  t�  � ��$�! �*� XY �" �7gu0� �& �"K� o. �$� � .  � / w� �< ��g]�%% � =Z � =Z � =0 � #0 � &t.????"=3��ux �=� ���2� � 8Z+ � 5Z2�+Y ����u�=�0�=v!"(�0 �BY� �7>� ��� �I.@ v  t�  �>/�Y �" �7g z. u[K!�A��v� ��Yg� �& ��! ���g �&�g ��=^���uuvug f� �&� �&����/�h����� ht J<� ����> � =Z � =0 � =0 � =? �t(???'�=`��u(� ��g �=�g �� �&�� �$= __clock_t _sigsys /src/work/stlinkserver/linux64/src short int sizetype sa_sigaction __pid_t _arch long long int si_status _upper si_overrun si_addr timezone signal_handler.c sa_handler tz_dsttime si_uid si_utime tz_minuteswest si_sigval GNU C99 5.4.0 20160609 -mtune=generic -march=x86-64 -g -g -g -std=gnu99 -std=gnu99 -std=gnu99 -fstack-protector-strong _sigfault __sigchld_clock_t _timer si_signo log_levels si_code si_band si_pid LOG_LVL_MAX siginfo _sifields unsigned char __sighandler_t si_fd long long unsigned int LOG_LVL_SILENT si_addr_bnd _sigpoll _syscall si_errno short unsigned int _pad sival_ptr __val LOG_LVL_INFO sa_flags _call_addr _Bool sa_mask si_addr_lsb LOG_LVL_ERROR si_tid si_stime sa_restorer __sigaction_handler sigval_t debug_level sival_int LOG_LVL_DEBUG __uid_t LOG_LVL_STLINK LOG_LVL_LIBUSB LOG_LVL_OUTPUT _lower install_ctrl_handler _sigchld siginfo_t LOG_LVL_WARN __sigset_t sin6_addr SOCKET __in6_u size_t __suseconds_t prev transaction_in_progress endpoint opened in_addr_t restart_after_error nth_sock data_buffer user_data HEART_BEAT_INTERVAL sockaddr_inarp bcdDevice connection_list actual_length __u6_addr16 LIBUSB_TRANSFER_STALL trace_ep LIBUSB_TRANSFER_NO_DEVICE timeval non_blocking_accept_main LIBUSB_TRANSFER_TIMED_OUT sockaddr_dl sin6_port uint16_t iManufacturer recd_data LIBUSB_TRANSFER_ERROR iProduct iso_packet_desc sockaddr_x25 LIBUSB_TRANSFER_COMPLETED sockaddr_ipx idProduct stlink_usb sin_zero bcdUSB dev_handle socks_in_fd_set s_addr bDeviceSubClass loop iSerialNumber b_exit asso timeout interval sin_addr ask_to_kill databuf sockaddr_in6 libusb_transfer_cb_fn bDescriptorType __u6_addr32 in_port_t libusb_transfer fds_bits is_socket_listening sockaddr_un is_list_empty sin_family exit_server libusb_device_descriptor sin6_family tv_sec rx_ep g_listening_sock_nb address_family sockaddr_ns bMaxPacketSize0 to_reopen send_offset dev_desc sin_port sa_family bDeviceProtocol sin6_scope_id sockaddr_iso socket_error stlink_usb_device __d1 __fd_mask data_size libusb_device accept.c LIBUSB_TRANSFER_OVERFLOW __mptr accept_context read_fd_set ready stlk_dev fw_major_ver tv_usec uint32_t stlink_assoc closed_for_refresh bNumConfigurations bDeviceClass sin6_flowinfo sockaddr __d0 tx_ep __u6_addr8 client_name libusb_iso_packet_descriptor sockaddr_ax25 num_iso_packets sockaddr_eon trans sockaddr_at __time_t sa_family_t bLength total_sent libusb_transfer_status sockaddr_in LIBUSB_TRANSFER_CANCELLED s_info uint8_t fw_jtag_ver cmdbuf serial listen_interface total_recd libusb_device_handle sa_data list_head is_fd_close_recd idVendor optarg parse_params version_flag long_options option has_arg argc argv auto_exit_flag help_flag cmdline.c option_index ai_family non_blocking IPPROTO_AH process_read_event ai_flags process_accept_event client_address_len IPPROTO_MTP IPPROTO_PIM addrinfo IPPROTO_DCCP sockaddr_storage SOCK_NONBLOCK IPPROTO_ENCAP IPPROTO_IGMP client_address get_stlink_tcp_cmd_data IPPROTO_UDP local res1 new_entry SOCK_STREAM destroy_listening_sockets IPPROTO_COMP SOCK_RDM ai_socktype IPPROTO_ESP send_data IPPROTO_RAW addr_len expected_size list_add_tail SOCK_CLOEXEC new_sock_info new_sock curr_entry print_address_string IPPROTO_TP IPPROTO_IPV6 timeout_retry CLEANUP close_socket_env init_sockinfo create_listening_sockets IPPROTO_TCP ai_protocol IPPROTO_MAX IPPROTO_RSVP SOCK_DCCP IPPROTO_BEETPH ai_addrlen __socket_type IPPROTO_PUP IPPROTO_SCTP IPPROTO_IDP ai_addr ai_next psock_info SOCK_PACKET total_received_size SOCKADDR_STORAGE IPPROTO_UDPLITE __socklen_t IPPROTO_EGP bytes_recd bytes_send IPPROTO_ICMP IPPROTO_GRE sock_addr IPPROTO_MPLS hints __ss_align SOCK_DGRAM p_data_buf common.c __ss_padding IPPROTO_IPIP SOCK_RAW ai_canonname SOCK_SEQPACKET LPSOCKADDR IPPROTO_IP __off_t _IO_read_ptr _chain _shortbuf _IO_buf_base log_init _fileno _IO_read_end log_output _IO_buf_end _cur_column _old_offset _IO_marker _IO_write_ptr _sbuf handle_log_output_command _IO_save_base _lock _flags2 log_out __gnuc_va_list _IO_write_end _IO_lock_t _IO_FILE _pos _markers file _vtable_offset format start_delay log_print log.c __off64_t _IO_read_base _IO_save_end __pad1 __pad2 __pad3 __pad4 __pad5 _unused2 stderr ms_delay _IO_backup_base ms_del log_strings _IO_write_base mediumStr minorStr majorStr rev_ver major minor medium tmp_ver build_ver get_version_cmd main_ver print_version internPtr main.c stlink_close stlink_open_device device_used stlink_get_device_info vendor_id stlink_get_device_info2 stlink_api.c stlink_usb_id enum_unique_id assoc_id delete_stlink_from_list list_to_count stlk_usb stlink_init get_stlink_by_key get_stlink_by_serial_name device_request_2 get_stlink_by_list_index stlink_send_command product_id dwTimeOut stlink_device_info stlink_get_nb_devices list_del input_request stlink_usb_list device_id serial_code buffer_size stlink_refresh jenkins_one_at_a_time_hash list_count key_to_find is_item_exist_in_stlink_list del_sock_info get_nb_tcp_client delete_sock_info_from_list alloc_sock_info free_sock_info sock_info.c sock_info_keys make_connection stlink_connection_invalid_usb wanted_client get_usb_number_client assoc_entry new_assoc_index get_nb_client_for_usb get_connection_by_sock usb_key get_tcp_number_client add_connection evaluate_auto_kill connection_count close_connection assoc_list stlink_connection.c get_connection_by_name already_exists new_connection power_ver size_of_input_cmd prec output_buf usd_dev_id internal_error dev_info_size res1_ver stlink_fw_version tcp_client_api_version bridge_ver res2_ver stlink_tcp_cmd.c connect_id error_convert tcp_cmd_error tcp_server_api_version p_answer_size_in_bytes token w_4_uint8_to_buf exclusive_access dev_info cmd_answ process_stlink_tcp_cmd input_buf seps msc_ver swim_ver stlink_mgt_send_cmd stlink_mgt_get_current_mode stlink_mgt_close_usb stlink_mgt_read_trace_data stlink_mgt_get_version stlink_mgt_open_usb_dbg_if cmdsize error_open stlink_mgt_exit_dfu_mode stlink_mgt_exit_jtag_mode stlink_mgt_dfu_exit stlink_mgt_jtag_exit stlink_mgt_init_buffer stlink_mgt.c stlink_usb_blink_led req_type fwvers result LIBUSB_DT_CONFIG LIBUSB_REQUEST_SYNCH_FRAME LIBUSB_SET_ISOCH_DELAY LIBUSB_REQUEST_GET_CONFIGURATION iInterface LIBUSB_DT_STRING LIBUSB_ERROR_INTERRUPTED serial_number LIBUSB_DT_HUB LIBUSB_REQUEST_SET_CONFIGURATION libusb_mgt_claim_interface list_move describe bInterval bInterfaceSubClass compute_serial_str LIBUSB_ERROR_NOT_SUPPORTED libusb_mgt.c LIBUSB_REQUEST_GET_INTERFACE LIBUSB_DT_INTERFACE devs LIBUSB_TRANSFER_TYPE_BULK LIBUSB_DT_SS_ENDPOINT_COMPANION libusb_mgt_refresh libusb_error bNumEndpoints LIBUSB_REQUEST_SET_SEL bInterfaceNumber LIBUSB_TRANSFER_TYPE_BULK_STREAM LIBUSB_DT_REPORT LIBUSB_REQUEST_CLEAR_FEATURE libusb_mgt_init_lib libusb_mgt_bulk_transfer LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_HID LIBUSB_ENDPOINT_OUT LIBUSB_ERROR_OVERFLOW MaxPower hotplug_callback LIBUSB_DT_BOS LIBUSB_DT_ENDPOINT LIBUSB_ERROR_OTHER current_config LIBUSB_TRANSFER_TYPE_CONTROL list_add libusb_descriptor_type b_malloc_err langid bInterfaceProtocol udev wTotalLength wMaxPacketSize bInterfaceClass LIBUSB_REQUEST_SET_DESCRIPTOR micro LIBUSB_ERROR_NO_DEVICE LIBUSB_ERROR_BUSY libusb_mgt_exit_lib errCode LIBUSB_REQUEST_SET_FEATURE LIBUSB_ERROR_TIMEOUT inter_desc libusb_hotplug_callback_handle extra_length libusb_mgt_init_refresh move_entry stlink_found LIBUSB_ENDPOINT_IN usb_delete_list libusb_endpoint_descriptor LIBUSB_TRANSFER_TYPE_INTERRUPT LIBUSB_REQUEST_GET_DESCRIPTOR a_libusb_context LIBUSB_ERROR_NOT_FOUND libusb_transfer_type extra libusb_interface bSynchAddress LIBUSB_REQUEST_SET_ADDRESS LIBUSB_ERROR_INVALID_PARAM hotplug_handle LIBUSB_SUCCESS LIBUSB_REQUEST_SET_INTERFACE libusb_config_descriptor libusb_endpoint_direction libusb_mgt_real_open libusb_interface_descriptor bNumInterfaces libusb_mgt_remove_device desc_index bEndpointAddress iConfiguration LIBUSB_DT_DEVICE tmp_entry libusb_standard_request LIBUSB_TRANSFER_TYPE_ISOCHRONOUS bmAttributes LIBUSB_DT_SUPERSPEED_HUB bConfigurationValue libusb_hotplug_event num_altsetting config_desc nano other_list_entry bAlternateSetting bRefresh LIBUSB_ERROR_ACCESS stlink_match libusb_mgt_set_configuration transferred if_id ep_id LIBUSB_DT_PHYSICAL libusb_version stlk_pids ep_desc new_stlink libusb_get_string_descriptor LIBUSB_ERROR_IO LIBUSB_ERROR_NO_MEM LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED LIBUSB_REQUEST_GET_STATUS LIBUSB_ERROR_PIPE LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT        M       `       D                      I      �      �      9      >      �                                                     8@                   T@                   t@                   �@                   �@                   X
@                   �@                   0@                  	 �@                  
 �@                   H@                   p@                  
    �@     �       #    �I@     e       9                     L                     e                     {    �>@     m       �    �M@     �      �    �B@     5       �                     �    �r@     �      �    �K@     ~          ��`            
                     
                     /
    <J@     �       M
                     _
    *A@     Y       x
                     �
                     �
    �@     (       �
    �O@     R       �
                     H     �`             �
    <�@     �      *    �@     *           �?@     �                            /    K@     �       ?    �&@           X     �`            g    	F@     X      {    ��`             �    �G@     �       �    �<@     U      �    �6@           �    �A@            �                     �                     �                     �                     �                         ={@     �       "                     :                     Q                     d                     x                      �    �@     $      �                     �    >P@     e       �    �P@     �       �    @     R      �                     
@     X
      4                             ^   ���o       �@     �      �                            k   ���o       0@     0      p                            z             �@     �      H                            �      B       �@     �      `                          �             H@     H                                    �             p@     p      P                            �             �@     �                                    �             �@     �      R�                             �             $�@     $�      	                              �             @�@     @�      �1                              �             �@     �                                   �              �@      �      \                             �             ��`     ��                                    �             ��`     ��                                    �             ��`     ��                                    �             ��`     ��                                  �             ��`     ��                                   �              �`      �      8                            �             @�`     @�      `                              �             ��`     ��      �                                    0               ��      5                                                  ��      @                                                  �      �z                             '                     �o                                  5                     ��     �#                             A     0               ��     �                             L                     W�     p                                                    ��     Z                                                   ��     �      $   Y                 	                      p�     s                                                                                                                                                             ./cleanup.sh                                                                                        0000755 0117457 0127674 00000000526 14060127025 012446  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

thisdir=$(readlink -m $(dirname $0))

cd $thisdir

# Selective cleanup as self extract may have been
# done in a user-created dir.

# Remove known objects
for item in $(cat pkg_rootdir_content.txt) root
do
        rm -rf $item
done

# Attempt to remove dir only if it's empty
if [ -z "$(ls -A)" ]; then
        rmdir $thisdir
fi
                                                                                                                                                                          ./pkg_rootdir_content.txt                                                                           0000644 0117457 0127674 00000000122 14060127026 015267  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 cleanup.sh
pkg_rootdir_content.txt
prompt_linux_license.sh
setup.sh
stlink-server
                                                                                                                                                                                                                                                                                                                                                                                                                                              ./prompt_linux_license.sh                                                                           0000644 0117457 0127674 00000020743 14060127025 015261  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

if [ "$LICENSE_ALREADY_ACCEPTED" ] ; then
	exit 0
fi

display_license() {
cat << EOF
STMicroelectronics Software License Agreement

SLA0048 Rev4/March 2018

Please indicate your acceptance or NON-acceptance by selecting "I ACCEPT" or "I DO NOT ACCEPT" as indicated below in the media.

BY INSTALLING COPYING, DOWNLOADING, ACCESSING OR OTHERWISE USING THIS SOFTWARE PACKAGE OR ANY PART THEREOF (AND THE RELATED DOCUMENTATION) FROM STMICROELECTRONICS INTERNATIONAL N.V, SWISS BRANCH AND/OR ITS AFFILIATED COMPANIES (STMICROELECTRONICS), THE RECIPIENT, ON BEHALF OF HIMSELF OR HERSELF, OR ON BEHALF OF ANY ENTITY BY WHICH SUCH RECIPIENT IS EMPLOYED AND/OR ENGAGED AGREES TO BE BOUND BY THIS SOFTWARE PACKAGE LICENSE AGREEMENT.

Under STMicroelectronics' intellectual property rights and subject to applicable licensing terms for any third-party software incorporated in this software package and applicable Open Source Terms (as defined here below), the redistribution, reproduction and use in source and binary forms of the software package or any part thereof, with or without modification, are permitted provided that the following conditions are met:
1. Redistribution of source code (modified or not) must retain any copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form, except as embedded into microcontroller or microprocessor device manufactured by or for STMicroelectronics or a software update for such device, must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of STMicroelectronics nor the names of other contributors to this software package may be used to endorse or promote products derived from this software package or part thereof without specific written permission.
4. This software package or any part thereof, including modifications and/or derivative works of this software package, must be used and execute solely and exclusively on or in combination with a microcontroller or a microprocessor devices manufactured by or for STMicroelectronics.
5. No use, reproduction or redistribution of this software package partially or totally may be done in any manner that would subject this software package to any Open Source Terms (as defined below).
6. Some portion of the software package may contain software subject to Open Source Terms (as defined below) applicable for each such portion ("Open Source Software"), as further specified in the software package. Such Open Source Software is supplied under the applicable Open Source Terms and is not subject to the terms and conditions of license hereunder. "Open Source Terms" shall mean any open source license which requires as part of distribution of software that the source code of such software is distributed therewith or otherwise made available, or open source license that substantially complies with the Open Source definition specified at www.opensource.org and any other comparable open source license such as for example GNU General Public License (GPL), Eclipse Public License (EPL), Apache Software License, BSD license and MIT license.
7. This software package may also include third party software as expressly specified in the software package subject to specific license terms from such third parties. Such third party software is supplied under such specific license terms and is not subject to the terms and conditions of license hereunder. By installing copying, downloading, accessing or otherwise using this software package, the recipient agrees to be bound by such license terms with regard to such third party software.
8. STMicroelectronics has no obligation to provide any maintenance, support or updates for the software package.
9. The software package is and will remain the exclusive property of STMicroelectronics and its licensors. The recipient will not take any action that jeopardizes STMicroelectronics and its licensors' proprietary rights or acquire any rights in the software package, except the limited rights specified hereunder.
10. The recipient shall comply with all applicable laws and regulations affecting the use of the software package or any part thereof including any applicable export control law or regulation.
11. Redistribution and use of this software package partially or any part thereof other than as permitted under this license is void and will automatically terminate your rights under this license.

THIS SOFTWARE PACKAGE IS PROVIDED BY STMICROELECTRONICS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS, IMPLIED OR STATUTORY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT OF THIRD PARTY INTELLECTUAL PROPERTY RIGHTS ARE DISCLAIMED TO THE FULLEST EXTENT PERMITTED BY LAW. IN NO EVENT SHALL STMICROELECTRONICS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EXCEPT AS EXPRESSLY PERMITTED HEREUNDER AND SUBJECT TO THE APPLICABLE LICENSING TERMS FOR ANY THIRD-PARTY SOFTWARE INCORPORATED IN THE SOFTWARE PACKAGE AND OPEN SOURCE TERMS AS APPLICABLE, NO LICENSE OR OTHER RIGHTS, WHETHER EXPRESS OR IMPLIED, ARE GRANTED UNDER ANY PATENT OR OTHER INTELLECTUAL PROPERTY RIGHTS OF STMICROELECTRONICS OR ANY THIRD PARTY.
EOF
}

# Make sure we use bash (#! may be overriden by caller script)
if [ "$(ps -o comm h -p $$)" != 'bash' ]
then
	exec /bin/bash "$0" "$@"
fi

export -f display_license

# Prompt user for license acceptance.
# Depending on options and environment, choose proper display tool.
# As terminal mode may not be detected when run from a script,
#   --force-console is here for automation purpose when testing. (ie. using expect)

set -e

box_title="STM32CubeIDE - License Agreement"

terminal_prompt() {
	rc_file=$1
	local rc

	typeset -l answer
	display_license | more
	echo
	read -p "I ACCEPT (y) / I DO NOT ACCEPT (N) [N/y] " answer
	if [ "$answer" = "y" ]; then
		# License accepted
		rc=0
		echo "License accepted."
	else
		# License not accepted
		rc=1
		echo "*** License NOT accepted. Not installing software. Hit return to exit."
		read
	fi

	# If exit code cannot be captured by caller, use this temp file
	if [ "$rc_file" ]
	then
		echo $rc > $rc_file
	fi

	exit $rc
}
export -f terminal_prompt

# Special treatment for RPM
if [[ ${BASH_SOURCE[0]} =~ '/var/tmp/rpm-tmp.' ]]; then
	if [ "$INTERACTIVE" = FALSE ] ; then
		# If not interactive and DISPLAY is not set (X11 installer seems to not propagate this variable)
		# then force it to :0
		export DISPLAY=${DISPLAY:-:0}
		# If this fails, then installation fails and user does not know it but what else can we do?
	else
		# Restore stdin as rpm installer closes it before running scriptlets.
		exec 0</dev/tty
	fi
fi

if [ -t 0 -o "$STM_FORCE_CONSOLE" ]
then
	# Terminal detected or wanted
	terminal_prompt

	# Unreached
	echo >&2 "Bug in $0 (terminal_prompt)"
	exit 3
fi

# No terminal
if [ -z "$DISPLAY" ]
then
	echo >&2 "DISPLAY not set. Cannot display license. Aborting."
	exit 2
fi


# Find first available X11 tool
dialog_tools="zenity xterm"
for tool in $dialog_tools
do
	if ( type >/dev/null -f $tool )
	then
		dialog=$tool
		break
	fi
done

case $dialog in
xterm)
	# Use terminal mode in an xterm

	# Workaround as xterm does not return "-e command" exit code
	exit_code_tmp_file=$(mktemp)
	xterm -title "$box_title" -ls -geometry 115x40 -sb -sl 1000 -e "terminal_prompt $exit_code_tmp_file"
	rc=$(cat $exit_code_tmp_file)
	rm $exit_code_tmp_file
	exit $rc
	;;
zenity)
	# Little trick below as default button of zenity is 'ok' and we want it to be 'cancel'.
	# So just swap buttons labels and use reverse condition for acceptance.
	display_license | zenity \
		--text-info \
		--title="$box_title" \
		--width=650 --height=500 \
		--cancel-label "I ACCEPT" \
		--ok-label "I DO NOT ACCEPT" \
		|| exit 0 # Accepted

	# Not accepted
	zenity \
		--error \
		--title="$box_title" \
		--text "License NOT accepted. Not installing software."
	exit 1
	;;
*)
	echo >&2 "No dialog tool found to display license. Aborting."
	exit 2
esac

# Should be unreached
echo >&2 "No way to display license. Aborting."
exit 3
                             ./setup.sh                                                                                          0000755 0117457 0127674 00000004721 14060127025 012160  0                                                                                                    ustar   morela                          gnbap3                                                                                                                                                                                                                 #!/bin/bash

thisdir=$(readlink -m $(dirname $0))

set -e
err_handler(){
	echo >&2 "Error installing stlink-server"
	exit 1
}

trap err_handler ERR
trap $thisdir/cleanup.sh EXIT

help() {
	echo "$0 usage:"
	echo "$0 [-f]"
	echo "   -f: do not check for downgrade"
}

# Ask user to agree on license
bash $thisdir/prompt_linux_license.sh
if [ $? -ne 0 ]
then
	exit 1
fi


stls_dir=/usr/bin
stls_abs_path=$stls_dir/stlink-server

# Arguments check
downgrade_check=1

case "$1" in
'')
	;;
-f)
	downgrade_check=
	;;
-h)
	help
	exit 0
	;;
*)
	help
	exit 1
	;;
esac

# Get version to be installed
set junk  $(./stlink-server 2>&1 -v)
tobe_installed_version_string=$3
# Below, strip off potential git describe string and 'v' prefix
tobe_installed_version=$(echo ${3%%-g*}|sed 's/^v//')
tobe_installed_timestamp=$4

echo "stlink-server $tobe_installed_version_string $tobe_installed_timestamp installation started."

if [ "$downgrade_check" -a -x $stls_abspath ] ; then
	# Check we do not downgrade already installed stlink-server
	downgrade_attempt=

	# Get already installed stlink-server version
	set junk  $($stls_abs_path 2>&1 -v)
	installed_version_string=$3
	# Below, strip off potential git describe string and 'v' prefix
	installed_version=$(echo ${3%%-g*}|sed 's/^v//')
	installed_timestamp=$4

	if [ "$installed_version" = "$tobe_installed_version" ]; then
		# If versions are the same then rely on timestamp
		newest_timestamp=$(
			(
				echo $installed_timestamp
				echo $tobe_installed_timestamp
			) |sort|tail -1
		)
		if [ "$newest_timestamp" = "$installed_timestamp" ]; then
			downgrade_attempt=yes
		fi
	else
		# Compare versions (without v prefix) sort -V (version-sort) not present on all linux so use sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n
		newest_version=$(
			(
				echo $installed_version
				echo $tobe_installed_version
			) |sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n|tail -1
		)
		if [ "$newest_version" = "$installed_version" ]; then
			downgrade_attempt=yes
		fi
	fi

	if [ "$downgrade_attempt" ]; then
		echo "Already installed version is newer or equal: $installed_version_string $installed_timestamp"
		echo "NOT downgrading. Aborting stlink-server installation."

		# This is not considered as a failure. Global installation must continue.
		exit 0
	fi

fi

# Finally, perform installation
echo "Stopping stlink-server (if any)..."
killall stlink-server -q || true
cp stlink-server $stls_dir
chmod 0755 $stls_abs_path
chown root:root $stls_abs_path

echo "Installation done."
exit 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               