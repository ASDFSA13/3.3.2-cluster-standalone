直接操作本地shell
-- 创建视图，引用本地 CSV 文件
CREATE TEMPORARY VIEW people
USING csv
OPTIONS (
  path 'C:/Users/Administrator/Desktop/spark/step1/spark-3.3.2-bin-hadoop3/spark-3.3.2-bin-hadoop3/data/people.csv',
  header 'true',
  inferSchema 'true'
);

-- 查询全部数据
SELECT * FROM people;
-- 查询年龄大于25的人
SELECT * FROM people WHERE age > 25;

cd C:\Users\Administrator\Desktop\spark\step1\spark-3.3.2-bin-hadoop3\spark-3.3.2-bin-hadoop3\bin

spark-sql.cmd --jars C:/Users/Administrator/Desktop/spark/step1/shell-demo/mysql-connector-java-8.0.33.jar

CREATE TEMPORARY VIEW users
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/spark_1?serverTimezone=UTC&useSSL=false&allowPublicKeyRetrieval=true',
  dbtable 'user_1',
  user 'root',
  password 'zyl123'
);

-- 查询数据库数据
SELECT * FROM users

-- 查询年龄大于30的用户
SELECT * FROM users WHERE age > 30;









https://chatgpt.com/c/67da1dd3-6ecc-8000-81b4-6864b686b9b0
