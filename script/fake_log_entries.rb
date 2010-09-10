#!/usr/bin/env ruby

require 'uri'
require 'net/http'

def get_referrer
  @referrers ||= [
    'http://www.google.com/#hl=en&source=hp&q=doug&aq=f&aqi=g10&aql=&oq=&gs_rfai=CnXkchr17TJLZG4WWhgTYv8CcBQAAAKoEBU_QYxBn&pbx=1&fp=1e07d8548a0a51',
    'http://www.google.com/#hl=en&source=hp&q=doug+youch&aq=f&aqi=g10&aql=&oq=&gs_rfai=CnXkchr17TJLZG4WWhgTYv8CcBQAAAKoEBU_QYxBn&pbx=1&fp=1e07d8548a0a51',
    'http://www.google.com/#hl=en&source=hp&q=blog&aq=f&aqi=g10&aql=&oq=&gs_rfai=CnXkchr17TJLZG4WWhgTYv8CcBQAAAKoEBU_QYxBn&pbx=1&fp=1e07d8548a0a51',
    'http://www.bing.com/search?q=doug&go=&form=QBLH&qs=n&sk=&sc=8-1',
    'http://search.yahoo.com/search;_ylt=AgBhhKR6mjVnil1VIPJFkgabvZx4?p=doug&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-954',
    'http://cykod.com/screencasts/view/2009-10-illustrator-fall-leaves-background'
  ]

  @referrers[rand(@referrers.size)]
end

def get_page
  @pages ||= [
    '/',
    '/news',
    '/blog',
    '/doc',
    '/user',
    '/companies',
    '/demo',
    '/doc/user/files-tab',
    '/doc/user/example-site'
    ]

  @pages[rand(@pages.size)]
end

def get_cookies(response)
  response.get_fields('set-cookie').collect { |cookie| cookie.split("\; ")[0] }.join("; ") + ";"
end

(1..20).each do |ses_idx|
  res = Net::HTTP.start('mywebiva.net', 80) do |http|
    http.request_get get_page, 'user-agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9) Gecko/2008051206 Firefox/3.0', 'referer' => get_referrer
  end

  cookies = get_cookies(res)

  Net::HTTP.start('www.doug.com', 80) do |http|
    (1..(2+rand(10))).each do |page_idx|
       http.request_get get_page, 'cookie' => cookies
     end
  end
end
