# Copyright (C) 2009 Pascal Rettig.

class Feedback::RatingsFeature < ParagraphFeature

  include PageHelper

  feature :ratings_page_ratings, :default_feature => <<-FEATURE
    <cms:rating>
      <div class="rating">
        Rating: <cms:widget/>
      </div>
    </cms:rating>
  FEATURE

  def ratings_page_ratings_feature(data)
    content = webiva_feature(:ratings_page_ratings) do |c|
      c.expansion_tag('rating') { |t| t.locals.rating = data[:feedback_rating] }
      c.expansion_tag('rating:ratable') { |t| t.locals.can_rate = data[:can_rate] }
      c.define_tag('rating:widget') do |t|
	rating = t.locals.rating.rating_sum
	count = t.locals.rating.rating_count
	options = { :stars => data[:options].max_stars,
	            :count => count,
	            :callback => "this.updateRating('#{data[:end_user_rating].target_hash}',"
	          }
	data[:can_rate] ? active_rating_widget( rating, options ) : rating_widget( rating, options )
      end
    end

    return content if documentation

    <<-RATING
    <div id='rating_#{paragraph.id}'>
      #{content}
      <script>
      document.ratingRating.updateRating = function(t, num) {
        document.ratingRating.clickStar = function(num){}
        document.ratingRating.highlightStar = function(num){}
        document.ratingRating.resetStar = function(num){}
        new Ajax.Request( '#{data[:rating_url]}', {parameters: 'target=' + t + '&rating=' + num,
			                           onSuccess: function(res) {
			                                        if(res.responseText != ''){
				                                  $('rating_#{paragraph.id}').replace(res.responseText);
                                                                }
                                                              }
                                                  });
      }
      </script>
    </div>
    RATING
  end
end
