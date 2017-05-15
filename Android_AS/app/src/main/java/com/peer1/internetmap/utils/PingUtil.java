package com.peer1.internetmap.utils;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * Created by shayla on 2017-05-12.
 */

public class PingUtil {

    public static void ping(String hostAddress) {

        Process p = null;
        try {
            p = new ProcessBuilder("sh").redirectErrorStream(true).start();
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }

        DataOutputStream os = new DataOutputStream(p.getOutputStream());
        try {
            os.writeBytes("ping -c 10 " + hostAddress + '\n');
            os.flush();

            // Close the terminal
            os.writeBytes("exit\n");
            os.flush();

        } catch (IOException e) {
            e.printStackTrace();
        }


        // read ping replys
        BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
        String line;


        try {
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
