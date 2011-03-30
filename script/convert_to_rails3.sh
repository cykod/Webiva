#!/bin/bash

find . -type f -exec perl -pi -e 's/<% tabled_form_for/<%= tabled_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% form_for/<%= form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% paragraph_options_form_for/<%= paragraph_options_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% remote_form_for/<%= remote_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% remote_cms_form_for/<%= remote_cms_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% tabled_display_form_for/<%= tabled_display_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% cms_unstyled_form_for/<%= cms_unstyled_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% link_edit_form_for/<%= link_edit_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% remote_tabled_form_for/<%= remote_tabled_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% tabular_form_for/<%= tabular_form_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% cms_fields_for/<%= cms_fields_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% cms_unstyled_fields_for/<%= cms_unstyled_fields_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% cms_subfields_for/<%= cms_subfields_for/g' {} \;
find . -type f -exec perl -pi -e 's/<% admin_fields_for/<%= admin_fields_for/g' {} \;

find . -type f -exec perl -pi -e "s/named_scope/scope/" {} \;


find . -type f -exec perl -pi -e "s/integrate_views/render_views/" {} \;

find . -type f -exec perl -pi -e 's/controller_name :page/subject { PageController.new }/' {} \;

find . -type f -exec perl -pi -e 's/require .*\/spec_helper.*/require "spec_helper"/' {} \;

find . -type f -exec perl -pi -e "s/\.status\.should == '200 OK'/.status.should == 200/" {} \;

find . -type f -exec perl -pi -e 's/<% stat_view/<%= stat_view/g' {} \;

find . -type f -exec perl -pi -e 's/<% active_table_for/<%= active_table_for/g' {} \;

find . -type f -exec perl -pi -e 's/<% action_panel/<%= action_panel/g' {} \;
find . -type f -exec perl -pi -e 's/<% more_action_panel/<%= more_action_panel/g' {} \;

find . -type f -exec perl -pi -e 's/<% ajax_tabs/<%= ajax_tabs/g' {} \;

find . -type f -exec perl -pi -e 's/<% t.tab do/<%= t.tab do/g' {} \;

find . -type f -exec perl -pi -e 's/errors.add_to_base\(/errors.add(:base, /' {} \;
find . -type f -exec perl -pi -e 's/errors.add_to_base /errors.add :base, /' {} \;
find . -type f -exec perl -pi -e 's/<% table_for/<%= table_for/g' {} \;

find . -type f -exec perl -pi -e 's/\.write_attribute\((\:\w+),\s*(\w+)\)/[$1] = $2/' {} \;
find . -type f -exec perl -pi -e 's/\.write_attribute (\:\w+),\s*(\w+)/[$1] = $2/' {} \;
find . -type f -exec perl -pi -e 's/\swrite_attribute\((\:\w+),\s*(\w+)\)/ self[$1] = $2/' {} \;
find . -type f -exec perl -pi -e 's/\swrite_attribute (\:\w+),\s*(\w+)/ self[$1] = $2/' {} \;


find . -type f -exec perl -pi -e 's/\.read_attribute\(\s*(\:\w+)\s*\)/[$1]/' {} \;
find . -type f -exec perl -pi -e 's/\.read_attribute (\:\w+)/[$1]/' {} \;
find . -type f -exec perl -pi -e 's/\sread_attribute\(\s*(\:\w+)\s*\)/self[$1]/' {} \;
find . -type f -exec perl -pi -e 's/\sread_attribute (\:\w+)/self[$1]/' {} \;

# this one is questionable
find . -type f -exec perl -pi -e 'if(/have_tag/) { s/\:text/:content/; s/have_tag/have_selector/; }' {} \;

