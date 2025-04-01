package com.airscholar.spark;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import scala.Tuple2;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;


public class WordCountJob
{
	private static final Pattern SPACE = Pattern.compile(" ");

    public static void main( String[] args )
    {
        // 初始化 Spark 配置和上下文
        SparkConf conf = new SparkConf().setAppName("SimpleWordCount");
        JavaSparkContext sc = new JavaSparkContext(conf);

        // 本地定义一个简单的字符串列表作为输入
        List<String> data = Arrays.asList(
                "hello world",
                "hello spark",
                "hello java"
        );

        // 创建 RDD
        JavaRDD<String> lines = sc.parallelize(data);

        // 执行 word count 并统计总词数
        long wordCount = lines
                .flatMap(line -> Arrays.asList(line.split(" ")).iterator())
                .count();

        // 输出结果
        System.out.println("Total word count: " + wordCount);

        // 关闭 Spark 上下文
        sc.close();
    }
}
