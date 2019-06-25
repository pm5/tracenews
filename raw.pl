#!/usr/bin/env perl -w

use Mojo::JSON qw/decode_json/;
use Mojo::CSV;
use Mojo::UserAgent;
use v5.10;

binmode STDOUT, ":utf8";

my $api_url = "http://page.board.tw/api/farm_news.php";

my $farm_data_filename = "data/farm.csv";
my $farm_data = {};
for my $row (@{Mojo::CSV->new->slurp($farm_data_filename)}) {
    $farm_data->{$row->[0]} = {
        farm_domain => $row->[1],
        farm_name => $row->[2],
    };
}

my $fanpage_data = {};
for my $row (@{Mojo::CSV->new->slurp("data/fanpage.csv")}) {
    $fanpage_data->{$row->[0]} = {
        fanpage_name => $row->[1],
        fanpage_link => $row->[2],
    };
}

sub find_farm_id {
    my $url = shift;
    for my $farm_id (keys %{$farm_data}) {
        return $farm_id if $url =~ $farm_data->{$farm_id}{farm_domain};
    }
    return "";
}

my $ua = Mojo::UserAgent->new;
my $data = $ua->get($api_url)
    ->result->json;

my @rows = ();

say "farm_news_id,farm_news_title,farm_news_url,farm_id,farm_name,fanpage_id,fanpage_name,post_id";
for my $farm_news_id (keys %{$data->{data}}) {
    my $farm_news = $data->{data}{$farm_news_id};
    my $farm_news_title = $farm_news->{title};
    $farm_news_title =~ s/,/ /g;
    my $farm_news_url = $farm_news->{url};
    my $farm_id = find_farm_id($farm_news_url);
    my $farm_name = $farm_data->{$farm_id}{farm_name};
    for my $fanpage_post_id (keys %{$farm_news->{posts}}) {
        my $post = $farm_news->{posts}{$fanpage_post_id};
        my $fanpage_id = $post->{fanpage_id};
        my $post_id = $post->{post_id};
        my $fanpage_name = $fanpage_data->{$fanpage_id}{fanpage_name} || $fanpage_id;
        say "$farm_news_id,$farm_news_title,$farm_news_url,$farm_id,$farm_name,$fanpage_id,$fanpage_name,$post_id";
    }
}
