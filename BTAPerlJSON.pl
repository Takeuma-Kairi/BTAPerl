#use utf8;	# このスクリプトはutf8。
use JSON;	# 基本の4つの関数がインポートされる
use Encode;

use strict;
use warnings;
use utf8;
use POSIX qw/ceil floor/;	#算術関数を使えるようにする(ceil,floor)

my @flgarr = ();	#フラグの配列
my @itearr = ();	#道具の配列
my @fiearr = ();	#場所の配列
my $fie = 0;		#場所番号
my @numarr = (0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0);	#補助的な数値列

#入出力はutf-8で行う。
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";


#==========================================
#使用可能な組み込み関数

#アイテム入手
sub geti{
	$itearr[$_[0]]->{"hav"} = 1;
};

#アイテム失う
sub losi{
	$itearr[$_[0]]->{"hav"} = 0;
};


#アイテムをもっている？
sub hav{
	return($itearr[$_[0]]->{"hav"});
};

#フラグをたてる
sub onflg{
	$flgarr[$_[0]] = 1;
};

#フラグをおろす
sub offlg{
	$flgarr[$_[0]] = 0;
};

#フラグを得る
sub iflg{
	return($flgarr[$_[0]]);
};

#数値を書き込む
sub wnum{
	$numarr[$_[0]] = $_[1];
};

#数値を読み取る
sub rnum{
	return($numarr[$_[0]]);
};

#数値の引き算
sub nminn{
    $numarr[$_[0]] -= $numarr[$_[1]];
};

#数値の引き算(与えた数で引き算)
sub nminx{
  $numarr[$_[0]] -= $_[1];
};

#数値の足し算
sub naddn{
  $numarr[$_[0]] += $numarr[$_[1]];
};

#数値の足し算(与えた数で足し算)
sub naddx{
   $numarr[$_[0]] += $_[1];
};

#Math.randomに同じ
sub myrand{
	return(rand 1); #0~0.99999...までの乱数を返す
}

#Math.floorに同じ(小数点切り捨て)
sub myflor{
	return(floor($_[0]));
}

#Math.ceilに同じ(小数点切り上げ)
sub myceil{
	return(ceil($_[0]));
}

#========================================
#マップの移動============================
sub mov{
	my $destination = -1;	#移動先が無い場合、このまま-1の値をとる
	$fie = $_[0];
	&show_page;
}

#===================================
#BTAPのページデータ配列からデータを配列・変数に入れていく
sub load_data{	
	my $input_json = $_[0];
	
	$input_json = Encode::encode("utf8", $input_json);
	
	# jsonをデコードしてハッシュに
	my $data_ref = decode_json($input_json);
	my $fie = $data_ref->{'fie'};	# fiearr配列のリファレンス
	my $ite = $data_ref->{'ite'};	# itearr配列のリファレンス

	@fiearr = @$fie;	
	@itearr = @$ite;
	
	#fiearrのマークアップ
	for(my $i = 0; $i <= $#fiearr; $i++){
		$fiearr[$i]->{nam} = &btascrModify($fiearr[$i]->{nam});
		$fiearr[$i]->{exp} = &btascrModify($fiearr[$i]->{exp});
		
		#選択肢配列もマークアップ
		my @tempsel = @{$fiearr[$i]->{sel}};
		for(my $j = 0; $j <= $#tempsel; $j++){
			$tempsel[$j]->[0] =  &btascrModify($tempsel[$j]->[0]);
			$tempsel[$j]->[1] =  &btascrModify($tempsel[$j]->[1]);
		}
		$fiearr[$i]->{sel} = \@tempsel;
	}
	
	#itearrのマークアップ
	for(my $i = 0; $i <= $#itearr; $i++){
		$itearr[$i]->{nam} = &btascrModify($itearr[$i]->{nam});
		$itearr[$i]->{exp} = &btascrModify($itearr[$i]->{exp});
	}
	
	print "### リードミー ###\n";	#リードミーを提示（道具配列一番最後に置いてある)
	print $itearr[$#itearr]->{exp} . "\n";
	&mov(0);
}

#=============================================
#JavaScript由来の文法などをperlに変更する======
sub btascrModify{
	my $modify = $_[0];
	
	#改行
	$modify =~ s/<br>/\n/g;
	
	#ルビのタグの消去
	$modify =~ s/<\/?ruby>//g;
	$modify =~ s/<\/?rp>//g;		
	$modify =~ s/<\/?rt>//g;		
	
	#強調。太字部は* * でくくることにした。
	$modify =~ s/<b>(.+?)<\/b>/ \*$1\* /g;
	
	#BTAPのルビ
	$modify =~ s/<r>(.+?)#(.+?)<\/r>/$1\($2\)/g;
	
	$modify =~ s/else if/elsif/g;
	
	$modify =~ s/&&/and/g;
	$modify =~ s/\|\|/or/g;
	
	#BTAPの埋め込み関数。&記号を前につけるのが特徴。
	$modify =~ s/mov/&mov/g;
	$modify =~ s/geti/&geti/g;
	$modify =~ s/losi/&losi/g;
	$modify =~ s/onflg/&onflg/g;
	$modify =~ s/offlg/&offlg/g;
	$modify =~ s/iflg/&iflg/g;
	$modify =~ s/wnum/&wnum/g;
	$modify =~ s/rnum/&rnum/g;
	$modify =~ s/nminn/&nminn/g;
	$modify =~ s/nminx/&nminx/g;
	$modify =~ s/naddx/&naddn/g;
	$modify =~ s/rand/&myrand/g;
	$modify =~ s/flor/&myflor/g;
	$modify =~ s/ceil/&myceil/g;

	return($modify);
}

#=============================================
#マップの表示=================================
sub show_page{
	my %nowfie = %{$fiearr[$fie]};	#マップ

	print "\n\n\n==[$nowfie{'nam'}]===========================\n";	#名前と説明
	print "$nowfie{'exp'}\n\n";
	print "0. 道具\n";
	
	my @selections = @{$nowfie{sel}};

	for(my $i = 0; $i <= $#selections; $i++){	#選択肢を走査して表示
	  my @unpacked_selections = @{$selections[$i]};
	  #0ではなく1から選択肢番号を振るので、$i+1とする。
	  print $i+1 . ". $unpacked_selections[0]\n";
	}

	while(1){	#入力がうまく行くまで繰り返す
		my $order = &getread;

		if ($order == 0) {	#道具の表示
			&show_item;
			last;
		}elsif($order > 0 and $order <= $#selections+1){	#ちゃんと選択したとき
			$order--; #0ではなく1から選択肢番号が振られているので、これを補正する
			eval("@{$selections[$order]}[1]");
			last;
		}elsif($order == -2){	#「quit」による終了
			print "さようなら！\n\n";
			last;
		}elsif($order == -3){	#ページ選択から再開
			&welcome;
			last;
		}

	}
}

#===================================
#道具の表示=========================
sub show_item{
	print "\n************************************\n";
	print   "*** 道具 ***************************\n";
	print "0. おわる\n";

	for(my $i = 0; $i<=$#itearr; $i++){	#道具の表示
		if ($itearr[$i]->{hav} == 1){
			#0ではなく1から選択肢番号を振るので、$i+1とする。
			print $i+1 . ". $itearr[$i]->{nam}\n";
		}
	}

	while(1){	#入力がうまく行くまで繰り返す
		my $select = &getread;

		if ($select > 0
				and $select <= $#itearr + 1
				and $itearr[$select-1]->{hav} == 1){
					#選択がうまくいった場合(選択肢番号が正しい範囲であり、また、
					#その道具をもっている場合

			print $itearr[$select-1]->{exp} . "\n";
		}elsif($select == 0){	#道具の終了。ページを表示する。
			&mov($fiearr[$fie]->{num});
			last;
		}elsif($select == -2){	#quitによる終了
			print "さようなら！\n\n";
			last;
		}elsif($select == -3){	#ページ選択から再開
			&welcome;
			last;
		}
	}
}

#=========================================
#入力に使える数か否か、および、quit、rebootのコマンドか
sub isNatural{	
	my $kazu = $_[0];
	if ($kazu =~ /^[0-9]+$/){	#入力で使える数
		return($kazu);
	}else{
		if($kazu eq "quit"){	#中止
			return(-2);
		}elsif($kazu eq "reboot"){	#ページ選択から再開
			return(-3);
		}else{	#無効な文字
			return(-1);
		}
	}
}

#=======================================
#入力。マップや道具表示時、これを用いる。
sub getread{	
	print "> ";
	my $temp = <STDIN>;
	chomp($temp);
	return(&isNatural($temp));
}
#========================================================
#ページデータを選ぶ======================================
sub select_pagefile{
	my @btascr;

	while(1){	#ファイル選択がうまく行くまで繰り返す
		print ">";
		my $fileSrc = <STDIN>;
		chomp($fileSrc);

		if ($fileSrc eq "quit"){	#「quit」で終了
			print "さようなら！\n";
			last;
		}elsif($fileSrc eq "reboot"){	#rebootでwelcomeから再開
			&welcome;
			last;
		}

		if(open(IN,"<:utf8",$fileSrc)){	#正常にファイルを選択した場合
			&load_data(<IN>);
			close(IN);
			last;
		}else{
			print "不正な指定です。\n";
		}
	}
}
#================================================
#起動後、一番最初に表示される画面=================
sub welcome{	
	print "Welcome to BTAPerl !(v0.0)(2021.08.14)\n\n";
	print "         =\n";
	print "      == || ==\n";
	print "   ==   ||||   ==\n";
	print "===    ||||||    ===\n";
	print "|||    ||||||    |||\n";
	print " |||  ||||||||  |||\n";
	print " |||  ||||||||  |||\n";
	print "  _ _ _ _  _ _ _ _\n";
	print "  = = = =  = = = =\n\n";

	print "[コマンド]\n";
	print "quit   -> BTAPerlの終了\n";
	print "reboot -> 再びこの画面へ\n\n";
	print "-------------------------\n";
	print "ページデータファイルの入力\n";

	&select_pagefile;
}

#=======================================================================

&welcome;