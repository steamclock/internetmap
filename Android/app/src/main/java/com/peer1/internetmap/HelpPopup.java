package com.peer1.internetmap;

import junit.framework.Assert;
import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NavUtils;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.SimpleOnPageChangeListener;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;

public class HelpPopup extends BaseActivity {
    private static String TAG = "HelpPopup";
    private int[] mSlideIDs; //resource ids for the slide images
    
    /**
     * Handles page switching and such for the ViewPager.
     */
    private class ImageAdapter extends PagerAdapter {

        @Override
        public int getCount() {
            return mSlideIDs.length;
        }

        @Override
        public boolean isViewFromObject(View view, Object object) {
            return view == object;
        }
        
        @Override
        public Object instantiateItem(View collection, int position) {
            ImageView imageView = new ImageView(HelpPopup.this);
            imageView.setImageResource(mSlideIDs[position]);
            
            ViewPager pager = (ViewPager) collection;
            Assert.assertNotNull(pager);
            pager.addView(imageView);
            return imageView;
        } 
        
        public void destroyItem(View collection, int position, Object view) {
            ((ViewPager) collection).removeView((ImageView) view);
        }
    }


    @SuppressLint("NewApi")
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            getActionBar().setDisplayHomeAsUpEnabled(true);
        }
        
        final ViewPager pager = (ViewPager) findViewById(R.id.pager);
        Assert.assertNotNull(pager);

        //pager slides
        int[] images = { R.drawable.help01, R.drawable.help02, R.drawable.help03 };
        mSlideIDs = images;
        ImageAdapter adapter = new ImageAdapter();
        pager.setAdapter(adapter);
        
        //next/close button
        final Button nextButton = (Button) findViewById(R.id.nextButton);
        nextButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                int next = pager.getCurrentItem() + 1;
                if (next >= mSlideIDs.length) {
                    //done
                    NavUtils.navigateUpFromSameTask(HelpPopup.this);
                } else {
                    //next slide
                    pager.setCurrentItem(next);
                }
            }
        });
        
        //update UI on page change
        final int[] dotsImages = { R.drawable.screen1_dots, R.drawable.screen2_dots, R.drawable.screen3_dots };
        pager.setOnPageChangeListener(new SimpleOnPageChangeListener() {
            public void onPageSelected (int position) {
                ImageView dots = (ImageView) findViewById(R.id.dots);
                dots.setImageResource(dotsImages[position]);
                boolean lastSlide = (position + 1) == mSlideIDs.length;
                nextButton.setText(lastSlide ? R.string.finish : R.string.next);
            }
        });
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case android.R.id.home:
            NavUtils.navigateUpFromSameTask(this);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        ViewPager pager = (ViewPager) findViewById(R.id.pager);
        int prev = pager.getCurrentItem() - 1;
        if (prev < 0) {
            //first slide: normal back behaviour
            super.onBackPressed();
        } else {
            //go back one slide
            pager.setCurrentItem(prev);
        }
    }
}
