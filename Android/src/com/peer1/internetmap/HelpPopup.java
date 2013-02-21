package com.peer1.internetmap;

import junit.framework.Assert;
import android.content.Context;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.SimpleOnPageChangeListener;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.PopupWindow;

public class HelpPopup extends PopupWindow{
    private static String TAG = "HelpPopup";
    private Context mContext;
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
            ImageView imageView = new ImageView(mContext);
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

    public HelpPopup(final InternetMap context, View view) {
        super(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;
        
        final ViewPager pager = (ViewPager) view.findViewById(R.id.pager);
        Assert.assertNotNull(pager);

        //pager slides
        int[] images = { R.drawable.screen1, R.drawable.screen2, R.drawable.screen3 };
        mSlideIDs = images;
        ImageAdapter adapter = new ImageAdapter();
        pager.setAdapter(adapter);
        
        //next/close button
        final Button nextButton = (Button) getContentView().findViewById(R.id.nextButton);
        nextButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                int next = pager.getCurrentItem() + 1;
                if (next >= mSlideIDs.length) {
                    //done
                    HelpPopup.this.dismiss();
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
                ImageView dots = (ImageView) getContentView().findViewById(R.id.dots);
                dots.setImageResource(dotsImages[position]);
                boolean lastSlide = (position + 1) == mSlideIDs.length;
                nextButton.setText(lastSlide ? R.string.finish : R.string.next);
            }
        });
    }
}
