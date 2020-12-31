/*
sql语句关键字执行顺序
-- 1、from子句组装来自不同数据源的数据
-- 1.2、join
-- 1.3、on
-- 2、where子句基于指定的条件对记录行进行筛选
-- 3、group by子句将数据划分为多个分组
-- 4、使用聚集函数进行计算 
-- 5、使用having子句筛选分组
-- 6、计算所有的表达式 
-- 7、select 的字段
-- 8、使用order by对结果集进行排序
-- 9、limit 页num,页size
*/
-- ------------------------------ 第1章 查询 --------------------------------------
-- cocncat() 将多列值合并为一列
SELECT concat(ename, ' WORK AS A ', job) as msg
FROM emp
WHERE deptno = 10;

-- case表达式可以对查询语句做条件逻辑判断，并且可以为case表达式的执行结果取一个别名
SELECT ename,sal,
	CASE WHEN sal <= 2000 THEN 'UNDERPAID'
		WHEN sal >= 400 THEN 'OVERPAID'
		ELSE 'OK'
	END AS status
FROM emp;

-- limit [pageNum,]PageSize
SELECT * FROM emp LIMIT 0,1;
-- 每页5条数据，返回第0页，页号从0开始
SELECT * FROM emp LIMIT 0,5;
SELECT * FROM emp LIMIT 5;

-- 随机返回5条记录
-- ORDER BY 可以接受一个函数的返回值，并利用该值改变当前结果集的顺序
SELECT ename,sal FROM emp ORDER BY RAND() LIMIT 5;

-- 寻找NULL值，NULL值不会等于或者不等于任何值，甚至不能与其自身比较，因此不能使用=或者!=
SELECT * FROM emp WHERE comm IS NULL;

-- NULL值转换，将NULL值替换为实际值
-- coalesce()函数可以接受一个或多个参数，这个函数会返回参数列表里的第一个非NULL值。
-- 若comm不为NULL则返回comm，否则返回0
SELECT ename,COALESCE(comm,0) FROM emp;

-- 多条件查询 in 和 like，like有两种通配符：_和%
SELECT ename,job FROM emp WHERE deptno in (10,20) AND (ename like '%I%' OR job LIKE '%ER');


-- ------------------------------ 第2章 排序--------------------------------------
-- ORDER BY 数值：从数值1开始，从左向右匹配SELECT列表中的列进行排序
SELECT ename,job,sal FROM emp WHERE deptno = 10 ORDER BY 3 ASC;

-- 多字段排序
SELECT * FROM emp ORDER BY deptno asc, sal desc;

-- 根据职位的最后三个字符对结果进行排序，SUBSTRING(str FROM pos FOR len)，pos从1开始
SELECT ename,job FROM emp ORDER BY SUBSTRING(job,LENGTH(job)-2,3);
SELECT job,SUBSTRING(job,LENGTH(job)-3+1,3) FROM emp;

-- 先创建一个视图，混合了字母和数字的数据
DROP  VIEW IF EXISTS view_letter_number;
CREATE VIEW view_letter_number
AS 
SELECT CONCAT(ename,' ',deptno) AS data FROM emp;
SELECT * FROM view_letter_number;

-- 排序时对null处理
-- 按照comm列对结果进行排序，但该字段可能为null，想个办法将null数据排在最后
SELECT ename,sal,comm FROM emp ORDER BY 3 DESC;
-- 可以看到降序的null值排在了最后，但是升序时null值还排在前面
SELECT ename,sal,comm FROM emp ORDER BY 3 ASC;
-- 添加一个辅助列，使用case来标记null值和非null值，可以随便控制null值的位置
SELECT ename,sal,comm 
FROM (
	SELECT ename,sal,comm,
		CASE WHEN comm IS NULL THEN 0 ELSE 1 END AS is_null 
	FROM emp
) x 
ORDER BY is_null desc,comm;

-- 根据条件逻辑动态调整排序项
-- 如果列job的值为SALESMAN，就按照COMM来排序，否则按照sal列来排序
SELECT ename,sal,job,comm,
	(CASE WHEN job = 'SALESMAN' THEN comm ELSE sal END) AS ordered 
FROM emp 
ORDER BY 5;

SELECT ename,sal,job,comm 
FROM emp 
ORDER BY (CASE WHEN job = 'SALESMAN' THEN comm ELSE sal end);


-- ------------------------------ 第3章 多表查询--------------------------------------
-- 将两个表的结果集进行叠加，使用union all，两个表的列的意义不一定相同，但两个表的列的数据类型必须相同
-- 将emp的部分记录和dept的全部记录进行叠加
SELECT ename AS ename_and_dname,deptno FROM emp WHERE  deptno = 10
	UNION ALL
SELECT '----------',NULL FROM t1
	UNION ALL
SELECT dname,deptno FROM dept;

-- union 不会返回重复记录
SELECT deptno FROM emp 
	UNION
SELECT deptno FROM dept;

-- 使用union可能会进行一次排序操作，以删除重复项，使用union相当于union all的输出结果进行一次distinct操作
-- 在查询中除非必要，否则不要使用distinct，或者使用union替代union all
SELECT DISTINCT deptno
FROM (
	SELECT deptno FROM emp 
		UNION ALL
	SELECT deptno FROM dept
	) x;

-- 将两个表中的不同字段合并到同一个结果集中，需要使用连接操作
SELECT e.ename,d.loc
FROM emp e,dept d
WHERE e.deptno = d.deptno AND e.deptno = 10;

SELECT e.ename,d.loc
FROM emp e
INNER JOIN dept d
	ON e.deptno = d.deptno
WHERE e.deptno = 10;

-- 从enp表中获取与视图view_emp_job_clerk相匹配的全部员工的empno,ename,job,sal,deptno
CREATE VIEW view_emp_job_clerk
AS
SELECT ename,job,sal
FROM emp
WHERE job = 'clerk';
SELECT * FROM view_emp_job_clerk;

SELECT e.empno,e.ename,e.job,e.sal,e.deptno
FROM emp e, view_emp_job_clerk v
WHERE e.ename = v.ename AND e.job = v.job AND e.sal = v.sal;

SELECT e.empno,e.ename,e.job,e.sal,e.deptno
FROM emp e
INNER JOIN view_emp_job_clerk v
	ON e.ename = v.ename AND e.job = v.job AND e.sal = v.sal;

-- 查询deptno在dept表中存在而在emp表中不存在的记录
SELECT deptno FROM dept WHERE deptno NOT IN (SELECT deptno from emp);
-- 谓词in本质是or语句，使用in或者or语句时要注意数据中是否有null值，因为(TRUE OR NULL)结果为True，而(FLASE OR NULL)结果为NULL,一旦表达式中混入了NULL，结果集就会一直保持为NULL。
SELECT deptno FROM dept WHERE deptno IN (20,30,40,NULL);
SELECT deptno FROM dept WHERE (deptno = 20 OR deptno = 30 OR deptno =40 OR deptno = NULL);
SELECT deptno FROM dept WHERE deptno NOT IN (10,50,NULL);
SELECT deptno FROM dept WHERE NOT (deptno = 10 OR deptno = 50 OR deptno = NULL);
-- 使用 NOT IN 语句，只要IN条件里有NULL值，查询结果就会为空
SELECT deptno FROM dept WHERE deptno NOT IN (NULL);
-- 使用 NOT EXISTS 语句将主语句和子语句连接后，即使子语句中的查询结果中有null值，也不会影响主语句的查询
-- 这个查询会对主语句的每个记录进行where判断，如果where中的NOT EXISTS为true则返回该行记录
-- 后面子句中的NULL没有实际意义，NULL可以为任何值，后面的子句只起一个作用，就是和主句进行关联
EXPLAIN 
SELECT d.deptno FROM dept d WHERE NOT EXISTS (SELECT NULL FROM emp e WHERE d.deptno = e.deptno);

-- 查找哪些部门没有员工，左连接找右表为null的记录
SELECT d.*
FROM dept d 
LEFT JOIN emp e ON d.deptno = e.deptno
WHERE e.deptno IS NULL;

-- 新增连接查询而不影响其他连接查询，这里还有一张奖金表

SELECT * FROM emp_bonus;
-- 如果本来已经有了以下查询，还想得到他们收到奖金的时间
SELECT e.ename,d.loc
FROM emp e,dept d
WHERE e.deptno = d.deptno;
-- 如果直接进行连接，没有奖金的员工将不会查询到
SELECT e.ename,d.loc,eb.received
FROM emp e,dept d,emp_bonus eb
WHERE e.deptno = d.deptno AND e.empno = eb.empno;
-- 可以先将emp和dept内联，然后将他两内联的结果进行左联emp_bonus
SELECT e.ename,d.loc,eb.received
FROM emp e 
INNER JOIN dept d ON e.deptno = d.deptno
LEFT JOIN emp_bonus eb ON e.empno = eb.empno;
-- 也可以使用标量子查询，把子查询放在select列表里
SELECT e.ename,d.loc,
	(SELECT eb.RECEIVED FROM emp_bonus eb 
		WHERE eb.empno = e.empno) AS received
FROM emp e 
INNER JOIN dept d ON e.deptno = d.deptno;

-- 确定两个表的数据是否相同（包括数据条数和每行的值），找出两个表的不同
CREATE VIEW view_emp_deptno_not_10_union_ward
AS
SELECT * FROM emp WHERE deptno != 10
	UNION ALL
SELECT * FROM emp WHERE ename = 'WARD';
SELECT * FROM view_emp_deptno_not_10_union_ward;
-- 找出存在于emp但不存在于view的数据，并且找出存在于view但不存在于emp的数据，然后union all
-- 找不同包括了不同的数据和虽然数据相同但是出现次数不同的数据
SELECT * 
FROM (
	SELECT e.empno,e.ename,e.job,e.mgr,e.hiredate,
		e.sal,e.comm,e.deptno,COUNT(*) AS cnt
	FROM emp e
	GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno
	) e 
WHERE NOT EXISTS (
	SELECT NULL 
	FROM (
		SELECT v.empno,v.ename,v.job,v.mgr,v.hiredate,
			v.sal,v.comm,v.deptno,COUNT(*) AS cnt
		FROM view_emp_deptno_not_10_union_ward v
		GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno
		) v
	WHERE v.empno = e.empno 
		AND v.ename = e.ename
		AND v.job = e.job
		AND v.mgr = e.mgr
		AND v.hiredate = e.hiredate
		AND v.sal = e.sal
		AND v.deptno = e.deptno
		AND v.cnt = e.cnt
		AND COALESCE(v.comm,0) = COALESCE(e.comm,0) 
	)
UNION ALL
SELECT * 
FROM (
	SELECT v.empno,v.ename,v.job,v.mgr,v.hiredate,
		v.sal,v.comm,v.deptno,COUNT(*) AS cnt
	FROM view_emp_deptno_not_10_union_ward v
	GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno
	) v
WHERE NOT EXISTS (
	SELECT NULL 
	FROM (
		SELECT e.empno,e.ename,e.job,e.mgr,e.hiredate,
			e.sal,e.comm,e.deptno,COUNT(*) AS cnt
		FROM emp e
		GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno
		) e 
	WHERE v.empno = e.empno 
		AND v.ename = e.ename
		AND v.job = e.job
		AND v.mgr = e.mgr
		AND v.hiredate = e.hiredate
		AND v.sal = e.sal
		AND v.deptno = e.deptno
		AND v.cnt = e.cnt
		AND COALESCE(v.comm,0) = COALESCE(e.comm,0) 
	);

-- 一个员工可以获得多个奖金，type=1的奖金为工资的10%，type=2的奖金为工资的20%	
SELECT * FROM emp_bonus_copy1;
-- 求部门为10的所有员工的工资和奖金总和
-- 先得到部门10的工资和奖金表
SELECT e.empno,e.ename,e.deptno,e.sal,
	e.sal * CASE WHEN eb.type = 1 THEN 0.1
				WHEN eb.type = 2 THEN 0.2
				WHEN eb.type = 3 THEN 0.3
				END AS bonus
FROM emp e,emp_bonus_copy1 eb
WHERE e.empno = eb.empno AND e.deptno = 10;
-- 然后求部门10的工资和奖金总和，下面计算是错误的，因为MILLER的工资计算了两次
SELECT deptno,SUM(sal) AS total_sal,SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.deptno,e.sal,
		e.sal * CASE WHEN eb.type = 1 THEN 0.1
					WHEN eb.type = 2 THEN 0.2
					WHEN eb.type = 3 THEN 0.3
					ELSE 0
					END AS bonus
	FROM emp e,emp_bonus_copy1 eb
	WHERE e.empno = eb.empno AND e.deptno = 10
	) x
GROUP BY deptno;
-- 可以在集合函数中使用distinct关键字去除工资中的重复，但是这种方法也不太对，那如果两个员工正好工资相同，去重会导致总工资变少
INSERT INTO emp (EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO) 
	VALUES (8888, '8888', '8888', 8888, '2020-12-09', 1300, NULL, 10);

SELECT deptno,SUM(DISTINCT sal) AS total_sal,SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.deptno,e.sal,
		e.sal * CASE WHEN eb.type = 1 THEN 0.1
					WHEN eb.type = 2 THEN 0.2
					WHEN eb.type = 3 THEN 0.3
					ELSE 0
					END AS bonus
	FROM emp e,emp_bonus_copy1 eb
	WHERE e.empno = eb.empno AND e.deptno = 10
	) x
GROUP BY deptno;
-- 先计算部门的总工资，然后连接emp和emp_bonus
SELECT deptno,total_sal,SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.deptno,d.total_sal,
		e.sal * CASE WHEN eb.type = 1 THEN 0.1
					WHEN eb.type = 2 THEN 0.2
					WHEN eb.type = 3 THEN 0.3
					ELSE 0
					END AS bonus
	FROM emp e,emp_bonus_copy1 eb,(
		SELECT deptno,SUM(sal) AS total_sal 
		FROM emp WHERE deptno = 10 
		GROUP BY deptno
		) d
	WHERE e.empno = eb.empno AND e.deptno = d.deptno AND e.deptno = 10 
	) x
GROUP BY deptno;

-- 如果奖金表中只有本部门的少部分员工有奖金，那么如果要计算总和，就不能使用inner join了
SELECT * FROM emp_bonus_copy2;
SELECT e.empno,e.ename,e.deptno,e.sal,
	e.sal * CASE WHEN eb.type = 1 THEN 0.1
				WHEN eb.type = 2 THEN 0.2
				WHEN eb.type = 3 THEN 0.3
				END AS bnous
FROM emp e LEFT JOIN emp_bonus_copy2 eb ON e.empno = eb.empno
WHERE e.deptno = 10;
-- 可以先将每个人的奖金求和，然后在计算所有人的工资和奖金
SELECT e.empno,e.ename,e.deptno,e.sal,
	SUM(e.sal * CASE WHEN eb.type = 1 THEN 0.1
				WHEN eb.type = 2 THEN 0.2
				WHEN eb.type = 3 THEN 0.3
				END) AS bnous
FROM emp e LEFT JOIN emp_bonus_copy2 eb ON e.empno = eb.empno
WHERE e.deptno = 10
GROUP BY EMPNO;
-- 这种方法和（先计算部门的总工资，然后连接emp和emp_bonus）结果相同
SELECT deptno,SUM(sal) AS total_sal,SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.deptno,e.sal,
		SUM(e.sal * CASE WHEN eb.type = 1 THEN 0.1
					WHEN eb.type = 2 THEN 0.2
					WHEN eb.type = 3 THEN 0.3
					END) AS bonus
	FROM emp e LEFT JOIN emp_bonus_copy2 eb ON e.empno = eb.empno
	WHERE e.deptno = 10
	GROUP BY empno
	) x
GROUP BY deptno;
SELECT deptno,total_sal,SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.deptno,d.total_sal,
		e.sal * CASE WHEN eb.type = 1 THEN 0.1
					WHEN eb.type = 2 THEN 0.2
					WHEN eb.type = 3 THEN 0.3
					ELSE 0
					END AS bonus
	FROM emp e,emp_bonus_copy2 eb,(
		SELECT deptno,SUM(sal) AS total_sal 
		FROM emp WHERE deptno = 10 
		GROUP BY deptno
		) d
	WHERE e.empno = eb.empno AND e.deptno = d.deptno AND e.deptno = 10 
	) x
GROUP BY deptno;

-- 找到存在于dept表中但不存在于emp表中的数据，即使没有员工也返回数据
SELECT d.deptno,d.dname,e.ename
FROM dept d
LEFT JOIN emp e
ON e.deptno = d.deptno;
-- 但是如果有一个员工不属于任何部门，那么在查询中怎么返回这个员工呢
INSERT INTO emp (EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO) 
	VALUES (1111, 'YODA', 'JEDI', NULL, '1980-12-17', 800, NULL, NULL);
-- 使用左连接缺失右边数据，使用右连接缺失左边数据，可以使用全外连接 FULL JOIN，mysql不支持全外连接
SELECT d.deptno,d.dname,e.ename
FROM dept d
FULL JOIN emp e
ON e.deptno = d.deptno;
-- 可以使用union拼接left join和right join的结果
SELECT d.deptno,d.dname,e.ename
FROM dept d
LEFT JOIN emp e
ON e.deptno = d.deptno
	UNION
SELECT d.deptno,d.dname,e.ename
FROM dept d
RIGHT JOIN emp e
ON e.deptno = d.deptno;

-- null值处理
-- NULL 不能等于或者不等于任何值，甚至不能与其自生比较，可以使用coalesce()将字段中的null转换为可以比较的值进行处理
SELECT * FROM emp WHERE 1 = 1;
SELECT * FROM emp WHERE NULL = NULL;
-- 找出业务提成（comm）比WARD低的所有员工，comm为null也得在结果集中
SELECT ename,comm 
FROM emp 
WHERE COALESCE(comm,0) < (
	SELECT comm 
	FROM emp 
	WHERE ename = 'WARD'
	);
-- 查看coalesce函数的执行结果
SELECT ename,comm,COALESCE(comm,0) 
FROM emp 
WHERE COALESCE(comm,0) < (
	SELECT comm 
	FROM emp 
	WHERE ename = 'WARD'
	);
	
-- ------------------------------ 第4章 增删改 --------------------------------------
-- 复制表定义，使用create table和一个不返回任何数据的子查询
-- where子句要指定一个不为true的条件，否则子句查询的结果会写入新表中
CREATE TABLE dept_east  AS 
SELECT * FROM dept WHERE 1=0;

-- 复制数据到另一张表
INSERT into dept_east (deptno,dname,loc) 
SELECT deptno,dname,loc FROM dept WHERE loc IN ('NEW YORK','BOSTON');

-- 将查询的结果集插入到多个目标表中，mysql暂不支持

-- 禁止插入特定的列，插入数据时只允许用户插入EMPNO ENAME JOB列
-- 可以创建只含有这三个字段的视图，向该视图中插入数据时
CREATE VIEW view_new_dept AS
SELECT empno,ename,job FROM emp WHERE 1 = 1;
-- 实际是向表中插入，只不过只插入了视图中有的字段
INSERT INTO view_new_dept (empno,ename,job) VALUES (1,'tom','Editor');

-- 对部门编号为20的员工统一加薪10%，update不指定where条件，那么会对所有数据进行更新
SELECT deptno,ename,sal 
FROM emp 
WHERE deptno = 20 
ORDER BY 1,3;
-- 条件update
UPDATE emp 
SET sal = sal * 1.10
WHERE deptno = 20;
-- 在大规模数据更新之前，可以先进行预览
SELECT 
	deptno,
	ename,
	sal AS orig_sal,
	sal * 0.1 AS amt_to_add,
	sal * 1.1 AS new_sal
FROM emp
WHERE deptno = 20
ORDER BY 1,5;

-- 根据一个表中是否存在相关行来更新另一个表中的部分数据
-- 如果一个员工在emp_bonus中存在，那么在emp表中把他的工资上涨20%
-- update set 的where子句中使用子查询
UPDATE emp 
SET sal = sal * 1.2 
WHERE empno IN (
	SELECT empno 
	FROM emp_bonus);
-- 也可以使用exists子查询，exists子句中只与子句的where中的条件有关，与select列表无关，因此这里可以用null
UPDATE emp e 
SET sal = sal * 1.2 
WHERE EXISTS (
	SELECT NULL 
	FROM emp_bonus eb 
	WHERE e.empno = eb.empno);
	
-- 使用另一个表的值来更新当前表，根据new_sal表的数据来更新emp表中部分员工的工资和业务提成
SELECT * FROM new_sal;
-- emp中的sal更新为new_sal中的sal，emp中的comm更新为new_sal中sal的50%
-- 可以应用关联子查询，但是set(,) = (,)貌似不太对
UPDATE emp e
SET (e.sal,e.comm) = (SELECT ns.sal AS sal,ns.sal/2 AS comm FROM new_sal ns WHERE ns.deptno = e.deptno) 
WHERE EXISTS (
	SELECT NULL 
	FROM new_sal ns1 
	WHERE ns1.deptno = e.deptno);
-- 试了一下，这样才可以，得每个列单独赋值
UPDATE emp e
SET e.sal = (SELECT ns.sal AS sal FROM new_sal ns WHERE ns.deptno = e.deptno),
	e.comm = (SELECT ns.sal/2 AS sal FROM new_sal ns WHERE ns.deptno = e.deptno)
WHERE EXISTS (
	SELECT NULL 
	FROM new_sal ns1 
	WHERE ns1.deptno = e.deptno);

-- 条件删除
DELETE FROM emp WHERE empno = 1;

-- 删除所在部门不存在的员工数据
INSERT INTO `emp` (`EMPNO`, `ENAME`, `JOB`, `MGR`, `HIREDATE`, `SAL`, `COMM`, `DEPTNO`) VALUES 
	(3333, '333', '333', 333, '2020-12-01', 33, 33, 50);
INSERT INTO `emp` (`EMPNO`, `ENAME`, `JOB`, `MGR`, `HIREDATE`, `SAL`, `COMM`, `DEPTNO`) VALUES 
	(4444, '444', '444', 44, '2020-12-17', 44, 44, NULL);
-- exists，会删除deptno不在dept表中的数据，还会删除deptno为null的数据
DELETE FROM emp
WHERE NOT EXISTS (
	SELECT NULL FROM dept 
	WHERE dept.deptno = emp.deptno);
-- in，只会删除deptno不在dept表中的数据
DELETE FROM emp
WHERE deptno NOT IN (
	SELECT deptno FROM dept);
	
-- 删除重复记录
DROP TABLE IF EXISTS dupes;
CREATE TABLE dupes(id INTEGER,name varchar(10));
INSERT INTO dupes VALUES (1,'NAPOLEON');
INSERT INTO dupes VALUES (2,'DYNAMITE');
INSERT INTO dupes VALUES (3,'DYNAMITE');
INSERT INTO dupes VALUES (4,'SHE SHLLS');
INSERT INTO dupes VALUES (5,'SHA SHLLS');
INSERT INTO dupes VALUES (6,'SHA SHLLS');
INSERT INTO dupes VALUES (7,'SHA SHLLS');
SELECT * FROM dupes;
-- 对于重复的数据，保留任意一条数据即可
-- SELECT * FROM dupes
-- 1093 - You can't specify target table 'dupes' for update in FROM clause
DELETE FROM dupes 
WHERE id NOT IN (
	SELECT MIN(id) FROM dupes 
	GROUP BY name);
-- 上面语句报错了，改用下面，查询通过一个临时中间表来操作
DELETE FROM dupes 
WHERE id NOT IN (
	SELECT * FROM (
		SELECT MIN(id) FROM dupes 
		GROUP BY name) tmp
	);
	
-- 删除一个表中被其他表参照的记录
DROP TABLE IF EXISTS dept_accidents;
CREATE TABLE dept_accidents(deptno INTEGER,accident_name varchar(20));
INSERT INTO dept_accidents VALUES (10,'BROKEN FOOT');
INSERT INTO dept_accidents VALUES (10,'FLESH WOUND');
INSERT INTO dept_accidents VALUES (20,'FIRE');
INSERT INTO dept_accidents VALUES (20,'FIRE');
INSERT INTO dept_accidents VALUES (20,'FLOOD');
INSERT INTO dept_accidents VALUES (30,'BRUISED GLUTE');
-- 每条数据记录生产事故，对于发生了3件以上事故的部门，从emp表中删除这些部门的全部员工记录
DELETE FROM emp
WHERE deptno IN (
	SELECT deptno 
	FROM dept_accidents 
	GROUP BY deptno 
	HAVING COUNT(*) >= 3
	);
	
-- ------------------------------ 第5章 元数据查询--------------------------------------
SHOW DATABASES;
USE mysql_learn;
SHOW TABLES;
SHOW COLUMNS FROM emp;

-- 列出某个模式里的所有表
SELECT table_name,table_type,table_schema,engine 
FROM information_schema.TABLES 
WHERE table_schema = 'mysql_learn';

-- 列出表中的字段信息
SELECT column_name,data_type,ordinal_position 
FROM information_schema.COLUMNS 
WHERE table_name = 'emp' AND table_schema = 'mysql_learn';

-- 列举索引列，列出表中构成索引的各列及其位置序号
SHOW INDEX FROM emp;

-- 列出模式里的某个表的约束，以及与这些约束相关的列
SELECT a.table_name,
	a.constraint_name,
	b.column_name,
	a.constraint_type
FROM information_schema.table_constraints a,
	information_schema.key_column_usage b
WHERE a.table_name = 'emp'
	AND a.table_schema = 'mysql_learn'
	AND a.table_name = b.table_name
	AND a.table_schema = b.table_schema
	AND a.constraint_name = b.constraint_name
	
-- 用sql生成sql，将某些维护任务自动化
-- 计算各个表的行数，禁用各个表的外键约束，根据表中的数据生成插入脚本
-- 生成计算各个表的行数的sql
SELECT CONCAT('SELECT COUNT(*) FROM ',table_name,';') AS cnts
FROM information_schema.tables
WHERE table_schema = 'mysql_learn';
-- 禁用所有表的外键约束
SELECT CONCAT('ALTER TABLE ',table_name,' DISABLE CONSTRAINT ',constraint_name,';') AS cons
FROM information_schema.table_constraints
WHERE table_schema = 'mysql_learn' AND constraint_type = 'FOREIGN KEY';
-- 根据emp表的某些列生成插入脚本
SELECT CONCAT('INSERT INTO emp(empno,ename,hiredate) ','VALUES(',empno,',\'',ename,'\',\'',hiredate,'\');') AS inserts
FROM emp
WHERE deptno = 10;
/* 用于执行动态sql的存储过程*/
DROP PROCEDURE IF EXISTS execute_insert;
CREATE PROCEDURE execute_insert()
BEGIN
	-- 定义用于接收每条插入语句的变量
	DECLARE insert_sql VARCHAR(200);
	
	-- 定义游标遍历时，作为判断是否遍历完全部记录的标记
	DECLARE no_next INTEGER DEFAULT 0;     	 
	-- 定义游标名字为 result
	DECLARE result CURSOR FOR
		SELECT CONCAT('INSERT INTO emp(empno,ename,hiredate) ','VALUES(',empno+10000,',\'',ename,'\',\'',hiredate,'\');') AS inserts
		FROM emp
		WHERE deptno = 10;
	-- 声明当游标遍历完全部记录后将标志变量置成某个值
	DECLARE CONTINUE HANDLER FOR NOT FOUND
			 SET no_next = 1;
	-- 打开游标
	OPEN result;
	FETCH result INTO insert_sql;
	WHILE no_next <> 1 DO
		-- 没有这句话执行的总是第一条语句，相对于循环并没有覆盖变量的值
		SET @insert_sql = insert_sql;
		SELECT insert_sql;
		PREPARE stmt FROM @insert_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		FETCH result INTO insert_sql;
	END WHILE;
	-- 关闭游标
	CLOSE result;
END;
-- 执行存储过程
CALL execute_insert();

-- ------------------------------ 第6章 字符串处理--------------------------------------
-- 遍历字符串中的每个字符
SELECT SUBSTRING(e.ename,pos,1) AS c
FROM (SELECT ename FROM emp WHERE ename = 'KING') e,
	(SELECT id AS pos FROM t10) iter
WHERE iter.pos <= LENGTH(e.ename);
-- 关键在于得到位置
SELECT e.ename,pos
FROM (SELECT ename FROM emp WHERE ename = 'KING') e,
	(SELECT id AS pos FROM t10) iter
WHERE iter.pos <= LENGTH(e.ename);

-- 字符串中嵌入引号，字符串常量中的单引号，用一对单引号表示''，也可以用转义\'
SELECT 'g''day maate'AS qmarks FROM t1 
UNION ALL
SELECT 'beavers\' teeth' AS qmarks FROM t1
UNION ALL
SELECT '''' AS qmarks FROM t1;

-- 统计字符出现的次数
-- '10,CLARK,MANAGER'中出现了多少个逗号，总长度减去除去逗号以后的长度，就是逗号的个数
SELECT (
	LENGTH('10,CLARK,MANAGER') 
	- LENGTH(REPLACE('10,CLARK,MANAGER',',',''))
	)/LENGTH(',') AS num 
FROM t1;

-- 统计'LL'出现了几次，这个时候就必须除 LENGTH('LL') 了
SELECT (LENGTH('HELLO HELLO') 
	- LENGTH(REPLACE('HELLO HELLO','LL',''))
	)/LENGTH('LL') AS correct_num ,
	(LENGTH('HELLO HELLO') 
	- LENGTH(REPLACE('HELLO HELLO','LL',''))
	) AS incorrect_num
FROM t1;

-- 删除所有的元音字母和数字0
SELECT ename,sal FROM emp;
SELECT ename,
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ename,'U',''),'O',''),'I',''),'E',''),'A','') AS ename1,
	sal,
	REPLACE(sal,0,'') AS sal1
FROM emp;

-- 分离数字和字符混合数据
SELECT CONCAT(ename,sal) AS data
FROM emp;
-- mysql 没有 translate函数

-- 判断只含有字母和数字的字符串
DROP VIEW IF EXISTS view_number_letter;
CREATE VIEW view_number_letter AS
SELECT ename AS data
FROM emp
WHERE deptno = 10
UNION ALL
SELECT CONCAT(ename,',$',CAST(sal AS CHAR(4)),'.00') AS data
FROM emp
WHERE deptno = 20
UNION ALL
SELECT CONCAT(ename,CAST(deptno AS CHAR(4))) AS data
FROM emp
WHERE deptno = 30;
SELECT * FROM view_number_letter;
-- 使用正则  ^取反（匹配除了表达式内的情况）
-- WHERE data REGEXP '[^0-9a-zA-Z]' = 0 的意思是，执行非字母和数字的匹配，返回结果为false的情况
-- 也就是返回只包含数字和字母的匹配
SELECT data FROM view_number_letter WHERE data REGEXP '[^0-9a-zA-Z]' = 0;

-- 根据子字符串排序
SELECT * FROM emp ORDER BY SUBSTRING(job,LENGTH(job)-2,3)

-- 创建分隔列表，将竖排列的数据转为横排列的数据,GROUP_CONCAT是一个聚合函数
SELECT deptno,GROUP_CONCAT(ename ORDER BY empno SEPARATOR ',') AS emps
FROM emp
GROUP BY deptno;

-- 将分隔数据转换为多值用在in列表中
SELECT empno,ename,sal,deptno
FROM emp
WHERE empno IN 
	(
	SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(list.vals,',',iter.pos),',',-1) AS empno
	FROM (SELECT id AS pos FROM t10) iter,(SELECT '7654,7689,7782,7788' AS vals FROM t1) list
	WHERE iter.pos <= (LENGTH(list.vals) - LENGTH(REPLACE(list.vals,',',''))) + 1
	) x;
/*
分析一下
WHERE iter.pos <= (LENGTH(list.vals) - LENGTH(REPLACE(list.vals,',',''))) + 1 用于得到被逗号分隔后的数值个数
SUBSTRING_INDEX(list.vals,',',iter.pos) 得到通过','分隔的list.vals，并且只返回从1开始的iter.pos个值(正数的话)
*/
SELECT list.vals,iter.pos,
	SUBSTRING_INDEX(list.vals,',',iter.pos),
	SUBSTRING_INDEX(SUBSTRING_INDEX(list.vals,',',iter.pos),',',-1)
FROM (SELECT id AS pos FROM t10) iter,(SELECT '7654,7689,7782,7788' AS vals FROM t1) list
WHERE iter.pos <= (LENGTH(list.vals) - LENGTH(REPLACE(list.vals,',',''))) + 1;
-- 正数：分隔后从开头位置取几个，负数：分隔后从结尾位置取几个
SELECT substring_index('www.baidu.com','.',1) FROM t1;
SELECT SUBSTRING_INDEX('www.baidu.com','.',2) FROM t1;
SELECT SUBSTRING_INDEX('www.baidu.com','.',-1) FROM t1;
SELECT SUBSTRING_INDEX('www.baidu.com','.',-2) FROM t1;
-- 取除了开头结尾的某段的话，需要两次SUBSTRING_INDEX操作
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('www.baidu.com','.',2),'.',-1) FROM t1;
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('www.baidu.com','.',-2),'.',1) FROM t1;

-- 对每个值，按照字母顺序重排列
-- 每个ename生成 1*length(ename) 个笛卡尔积，总共生成 count(ename)*length(ename)个笛卡尔积
SELECT ename,SUBSTRING(e.ename,iter.pos,1) c 
FROM emp e,(SELECT id AS pos FROM t10) iter 
WHERE iter.pos <= LENGTH(e.ename);
-- 然后聚合重排后的c
SELECT ename AS old_ename,GROUP_CONCAT(c ORDER BY c SEPARATOR '') AS new_ename
FROM (
	SELECT ename,SUBSTRING(e.ename,iter.pos,1) c 
	FROM emp e,(SELECT id AS pos FROM t10) iter 
	WHERE iter.pos <= LENGTH(e.ename)
	) x
GROUP BY x.ename

-- 解析ip地址 '111.22.3.4'，使用 SUBSTRING_INDEX(str,delim,count)
SELECT '111.22.3.4' AS ip FROM t1;
-- 将ip切分放入行中
SELECT *
FROM (
	SELECT iter.pos,list.ip,SUBSTRING_INDEX(SUBSTRING_INDEX(list.ip,'.',iter.pos),'.',-1) AS num
	FROM (SELECT id AS pos FROM t10) iter,(SELECT '111.22.3.4' AS ip FROM t1) list
	WHERE iter.pos <= LENGTH(list.ip) - LENGTH(REPLACE(list.ip,'.','')) +1
	) num_list;
-- 使用case和group将多行数据转为多列数据
SELECT
	MAX(CASE num_list.pos WHEN 1 THEN num_list.num ELSE NULL END) AS a,
	MAX(CASE num_list.pos WHEN 2 THEN num_list.num ELSE NULL END) AS b,
	MAX(CASE num_list.pos WHEN 3 THEN num_list.num ELSE NULL END) AS c,
	MAX(CASE num_list.pos WHEN 4 THEN num_list.num ELSE NULL END) AS d
FROM (
	SELECT iter.pos,list.ip,SUBSTRING_INDEX(SUBSTRING_INDEX(list.ip,'.',iter.pos),'.',-1) AS num
	FROM (SELECT id AS pos FROM t10) iter,(SELECT '111.22.3.4' AS ip FROM t1) list
	WHERE iter.pos <= LENGTH(list.ip) - LENGTH(REPLACE(list.ip,'.','')) +1
	) num_list
GROUP BY num_list.ip;
-- case when的两种不同用法
SELECT
	MAX(CASE WHEN num_list.pos = 1 THEN num_list.num ELSE NULL END) AS a,
	MAX(CASE WHEN num_list.pos = 2 THEN num_list.num ELSE NULL END) AS b,
	MAX(CASE WHEN num_list.pos = 3 THEN num_list.num ELSE NULL END) AS c,
	MAX(CASE WHEN num_list.pos = 4 THEN num_list.num ELSE NULL END) AS d
FROM (
	SELECT iter.pos,list.ip,SUBSTRING_INDEX(SUBSTRING_INDEX(list.ip,'.',iter.pos),'.',-1) AS num
	FROM (SELECT id AS pos FROM t10) iter,(SELECT '111.22.3.4' AS ip FROM t1) list
	WHERE iter.pos <= LENGTH(list.ip) - LENGTH(REPLACE(list.ip,'.','')) +1
	) num_list
GROUP BY num_list.ip;

-- ------------------------------ 第7章 数值处理--------------------------------------
-- 平均值 avg()
CREATE TABLE t2 (sal INTEGER);
INSERT INTO t2 VALUES (10);
INSERT INTO t2 VALUES (20);
INSERT INTO t2 VALUES (NULL);
-- avg() 函数会自动忽略null值，有几个null值平均时就会少几个分母
SELECT AVG(sal) FROM t2;
SELECT DISTINCT 30/2 FROM t2;
-- 如果想要null值的行参与运算，需要使用coalesce()函数
SELECT AVG(COALESCE(sal,0)) FROM t2;
SELECT DISTINCT 30/3 FROM t2;
-- 求部门的平均值
SELECT deptno,AVG(sal) FROM emp GROUP BY deptno;

-- 最大最小值 max() min()，会自动忽略NULL值
-- 求所有记录的最值不需要使用分组
SELECT MAX(sal),MIN(sal) FROM emp;
-- 分部门的最值
SELECT deptno,MAX(sal),MIN(sal) FROM emp GROUP BY deptno;
-- 看一下null的情况
SELECT deptno,comm FROM emp WHERE deptno IN (10,30) ORDER BY 1;
SELECT MAX(comm),MIN(comm) FROM emp;
SELECT deptno,MAX(comm),MIN(comm) FROM emp GROUP BY deptno;

-- 求薪资总和
SELECT SUM(sal) FROM emp;
-- 求部门薪资总和
SELECT deptno,SUM(sal) FROM emp GROUP BY deptno;
-- sum会自动忽略null，如果需要处理为实际意义的值，可以借助coalesce
SELECT deptno,comm FROM emp WHERE deptno IN (10,30) ORDER BY 1;
SELECT deptno,SUM(comm) FROM emp WHERE deptno IN (10,30) GROUP BY deptno;
SELECT deptno,COALESCE(SUM(comm),0) FROM emp WHERE deptno IN (10,30) GROUP BY deptno;

-- 计算某列中值得个数
SELECT COUNT(*) FROM emp;
SELECT deptno,COUNT(*) FROM emp GROUP BY deptno;

-- 使用列名作为count的参数时，count会忽略null，如果使用*或者常量参数时就会包含null
SELECT deptno,comm FROM emp;
SELECT COUNT(*),COUNT(1),COUNT(2),COUNT('HELLO'),COUNT(deptno),COUNT(comm) FROM emp;
SELECT deptno,COUNT(*) FROM emp GROUP BY deptno;

-- 针对某一列进行累计求和
-- 求员工工资的累计额
-- WHERE a.empno <= b.empno 我感觉这么做的前提条件是empno是升序有序的
SELECT empno,ename,sal,
	(SELECT SUM(a.sal) FROM emp a WHERE a.empno <= b.empno) AS running_total
FROM emp b;
-- from的子查询中先对empno排序，保证empno整体有序
SELECT empno,ename,sal,
	(SELECT SUM(y.sal) FROM emp y WHERE y.empno <= x.empno) AS running_total
FROM (SELECT empno,ename,sal FROM emp ORDER BY empno) x;

-- 累计乘积  
SELECT empno,ename,sal,
	(SELECT 
		EXP(SUM(LN(y.sal))) 
	FROM emp y 
	WHERE y.empno <= x.empno 
		AND y.deptno = x.deptno
	) AS running_prod
FROM (
	SELECT empno,ename,sal,deptno 
	FROM emp 
	ORDER BY empno
	) x
WHERE x.deptno = 10;
-- 借助于exp(ln(x)) = x, xy = exp(ln(x) + ln(y))
SELECT EXP(LN(2) + LN(3)), 2*3;

-- 累计差
SELECT empno,ename,sal,
	(SELECT 
		CASE WHEN x.empno = MIN(y.empno) THEN x.sal ELSE -x.sal END
	FROM emp y 
	WHERE y.empno <= x.empno 
		AND y.deptno = x.deptno
	) AS running_minus
FROM (
	SELECT empno,ename,sal,deptno 
	FROM emp 
	ORDER BY empno
	) x
WHERE x.deptno = 10;
-- 把上面的查询作为from子查询做累计求和操作
SELECT empno,ename,sal,
	(SELECT SUM(b.running_minus) FROM (
		SELECT empno,ename,sal,
			(SELECT 
				CASE WHEN x.empno = MIN(y.empno) THEN x.sal ELSE -x.sal END
			FROM emp y 
			WHERE y.empno <= x.empno 
				AND y.deptno = x.deptno
			) AS running_minus
		FROM (
			SELECT empno,ename,sal,deptno 
			FROM emp 
			ORDER BY empno
			) x
		WHERE x.deptno = 10
		) b 
	WHERE b.empno <= a.empno) AS running_diff
FROM (
	SELECT empno,ename,sal,
		(SELECT 
			CASE WHEN x.empno = MIN(y.empno) THEN x.sal ELSE -x.sal END
		FROM emp y 
		WHERE y.empno <= x.empno 
			AND y.deptno = x.deptno
		) AS running_minus
	FROM (
		SELECT empno,ename,sal,deptno 
		FROM emp 
		ORDER BY empno
		) x
	WHERE x.deptno = 10
	) a;
-- 为了方便，创建一个视图并且为第一条数据创建标记
DROP VIEW IF EXISTS view_running_diff;
CREATE VIEW view_running_diff AS
	SELECT empno,ename,sal,
		(SELECT 
			CASE WHEN x.empno = MIN(y.empno) THEN '库存' ELSE '出库' END
		FROM emp y 
		WHERE y.empno <= x.empno 
			AND y.deptno = x.deptno
		) AS type
	FROM (
		SELECT empno,ename,sal,deptno 
		FROM emp 
		ORDER BY empno
		) x
	WHERE x.deptno = 10;
-- 对视图进行累计求差
SELECT empno,ename,sal,
	(CASE WHEN x.type = '库存' THEN x.sal ELSE -x.sal END) AS running_minus,
	(SELECT SUM(CASE WHEN y.type = '库存' THEN y.sal ELSE -y.sal END) 
		FROM view_running_diff y WHERE y.empno <= x.empno) AS running_diff
FROM view_running_diff x;

-- 计算众数
-- >= all  相对于 大于子查询中的最大值
SELECT sal
FROM emp
WHERE deptno = 20
GROUP BY sal
HAVING COUNT(*) >= ALL(SELECT COUNT(*) FROM emp WHERE deptno = 20 GROUP BY sal);

-- 计算中位数
SELECT sal FROM emp WHERE deptno = 20 ORDER BY sal;
SELECT AVG(sal) FROM (
	SELECT e.sal
	FROM emp e,emp d
	WHERE e.deptno = d.deptno AND e.deptno = 20
	GROUP BY e.sal
	HAVING SUM(CASE WHEN e.sal = d.sal THEN 1 ELSE 0 END) >= ABS(SUM(SIGN(e.sal - d.sal)))
	) x;
-- ABS(SUM(SIGN(e.sal - d.sal))) 越小说明这个sal越在中间，因为比它大的数和比它小的数基本相等，
-- 绝对值要不为0，要不为1，为0时证明这个数在最中间，为1时肯定有两个这样的数，这时就取了一个平均值作为中位数
SELECT e.sal,SUM(CASE WHEN e.sal = d.sal THEN 1 ELSE 0 END) AS cnt1,ABS(SUM(SIGN(e.sal - d.sal))) AS cnt2
FROM emp e,emp d
WHERE e.deptno = d.deptno AND e.deptno = 20
GROUP BY e.sal;

-- 计算百分比
-- 计算某一列的某部分值占本列值总和的百分比
SELECT SUM(CASE WHEN deptno = 10 THEN sal END) AS d10,
	SUM(sal) AS total,
	(SUM(CASE WHEN deptno = 10 THEN sal END) / SUM(sal) * 100) AS pct 
FROM emp;

-- 去掉最大值和最小值
SELECT AVG(sal)
FROM emp
WHERE sal NOT IN(
	(SELECT MIN(sal) FROM emp),
	(SELECT MAX(sal) FROM emp)
	);

-- 修改累计值
-- 一个流水表，amt为金额，trx为交易类型，PR表示支出，PY表示存入
DROP VIEW IF EXISTS view_bank_water;
CREATE VIEW view_bank_water(id,amt,trx) AS
SELECT 1,100,'PR' FROM t1 UNION ALL
SELECT 2,100,'PR' FROM t1 UNION ALL
SELECT 3,50,'PY' FROM t1 UNION ALL
SELECT 4,100,'PR' FROM t1 UNION ALL
SELECT 5,200,'PY' FROM t1 UNION ALL
SELECT 6,50,'PY' FROM t1;
SELECT * FROM view_bank_water;
-- 根据流水，显示每次交易完的余额
-- 如果是PR加上当前amt，如果是PY减去当前amt
SELECT 
	(CASE WHEN v1.trx = 'PY' THEN 'PAYMENT' ELSE 'PURCHASE' END) AS trx_type,
	v1.amt,
	(
		SELECT SUM(CASE WHEN v2.trx = 'PY' THEN -v2.amt ELSE v2.amt END) 
		FROM view_bank_water v2 
		WHERE v2.id <= v1.id
	) AS balance
FROM view_bank_water v1

-- ------------------------------ 第8章 日期运算--------------------------------------
-- 年月日加减法 
-- CLARK 入职（HIREDATE）前后五天，入职前后五个月，入职千户五年的日期
-- 使用 INTERVAL 关键字指定要加上或者减去的时间单位
SELECT hiredate,
	hiredate - INTERVAL 5 DAY AS hd_minus_5D,
	hiredate + INTERVAL 5 DAY AS hd_plus_5D,
	hiredate - INTERVAL 5 MONTH AS hd_minus_5M,
	hiredate + INTERVAL 5 MONTH AS hd_plus_5M,
	hiredate - INTERVAL 5 YEAR AS hd_minus_5Y,
	hiredate + INTERVAL 5 YEAR AS hd_plus_5Y
FROM emp
WHERE ename = 'CLARK';

-- 计算两个日期之间的差距
SELECT DAY(hd_ward) - DAY(hd_allen) 
FROM 
	(
	SELECT hiredate AS hd_ward FROM emp WHERE ename = 'WARD'
	) x,
	(
	SELECT hiredate AS hd_allen FROM emp WHERE ename = 'ALLEN'
	) y ;
-- 或者使用datediff函数
SELECT DATEDIFF(hd_ward,hd_allen)
FROM 
	(
	SELECT hiredate AS hd_ward FROM emp WHERE ename = 'WARD'
	) x,
	(
	SELECT hiredate AS hd_allen FROM emp WHERE ename = 'ALLEN'
	) y ;

-- 计算两个日期之间的工作日天数，并且这两天也要算进去,开始和结束日期分别是BLAKE和JONES的hiredate
SELECT ename,hiredate FROM emp WHERE ename IN ('BLAKE','JONES');
-- SELECT x.*,t100.*,DATE_ADD(hd_jones,INTERVAL t100.id - 1 DAY),DATE_FORMAT(DATE_ADD(hd_jones,INTERVAL t100.id - 1 DAY),'%a')
-- DATE_ADD(hd_jones,INTERVAL t100.id - 1 DAY) 可以得到开始日期+n天后的日期
-- DATE_FORMAT(DATE_ADD(hd_jones,INTERVAL t100.id - 1 DAY),'%a') 可以得到某个日期是周几('%a')
SELECT 
	SUM(
		CASE WHEN 
			DATE_FORMAT(
				DATE_ADD(hd_jones,INTERVAL t100.id - 1 DAY),'%a') 
			IN ('Sat','Sun') 
		THEN 0 
		ELSE 1 
		END
	) AS days
FROM
	(
	SELECT 
		MAX(CASE WHEN ename = 'BLAKE' THEN hiredate END) AS hd_blake,
		MAX(CASE WHEN ename = 'JONES' THEN hiredate END) AS hd_jones 
	FROM emp 
	WHERE ename IN ('BLAKE','JONES')
	) x,
	t100
WHERE t100.id <= DATEDIFF(hd_blake,hd_jones) + 1;

-- 计算两个日期之间相差的年数或者月数
SELECT MIN(hiredate) AS min_hd,MAX(hiredate) AS max_hd FROM emp;
SELECT mnth,mnth/12
FROM (
	SELECT 
		(YEAR(max_hd) - YEAR(min_hd))*12 + 
		MONTH(max_hd) - MONTH(min_hd) 
		AS mnth
	FROM (
		SELECT MIN(hiredate) AS min_hd,MAX(hiredate) AS max_hd FROM emp
		) d
	) m;
	
-- 计算两个日期之间相差的秒数、分钟数和小时数
SELECT 
	DATEDIFF(hd_blake,hd_jones) * 24 AS hr,
	DATEDIFF(hd_blake,hd_jones) * 24 * 60 AS min,
	DATEDIFF(hd_blake,hd_jones) * 24 * 60 * 60 AS sec
FROM (
	SELECT 
		MAX(CASE WHEN ename = 'BLAKE' THEN hiredate END) AS hd_blake,
		MAX(CASE WHEN ename = 'JONES' THEN hiredate END) AS hd_jones 
	FROM emp 
	) x;
	
-- 查今年有几个星期一
-- CAST(value AS type) 将value转为type类型
SELECT 
	DATE_FORMAT(
		DATE_ADD(
			CAST(CONCAT(YEAR(CURRENT_DATE),'-01-01') AS date),
			INTERVAL t500.id-1 DAY),
		'%W') AS day,
	COUNT(*) AS cnt
FROM t500
WHERE t500.id <= 
	(
	DATEDIFF(
		CAST(CONCAT(YEAR(CURRENT_DATE)+1,'-01-01') AS date),
		CAST(CONCAT(YEAR(CURRENT_DATE),'-01-01') AS date)
		)
	)
GROUP BY 
	DATE_FORMAT(
		DATE_ADD(
			CAST(CONCAT(YEAR(CURRENT_DATE),'-01-01') AS date),
			INTERVAL t500.id-1 DAY),
		'%W')
HAVING day = 'Monday';

-- 计算当前记录和下一条记录之间的日期差
-- 计算deptno=10的员工入职分别相差多少天，比curr大的hd里面最小的一个就是next_hd_more_curr
SELECT x.*,DATEDIFF(x.hiredate,next_hd_more_curr)
FROM (
	SELECT e.deptno,e.ename,e.hiredate,(
		SELECT COALESCE(MIN(d.hiredate),d.hiredate) 
		FROM emp d 
		WHERE deptno = 10 AND d.hiredate > e.hiredate
		) AS next_hd_more_curr
	FROM emp e
	WHERE deptno = 10
	) x;
	
-- ------------------------------ 第9章 日期处理--------------------------------------
-- 判断某一年是否是闰年  查找这一年2月的最后一天
SELECT 
	DAY(
		LAST_DAY(
			DATE_ADD(
				DATE_ADD(
					DATE_ADD(CURRENT_DATE,
						INTERVAL -DAYOFYEAR(CURRENT_DATE) DAY),
				INTERVAL 1 DAY),
			INTERVAL 1 MONTH)
		)
	) dy 
FROM t1;

-- 计算一年有多少天
-- DAYOFYEAR 今天是今年的第几天
SELECT CURRENT_DATE,DAYOFYEAR(CURRENT_DATE) FROM t1;
SELECT DATEDIFF((curr_year_start + INTERVAL 1 YEAR),curr_year_start)
FROM (
	SELECT ADDDATE(CURRENT_DATE,-DAYOFYEAR(CURRENT_DATE)+1) AS curr_year_start
	FROM t1
	) x;
	
-- 从给定日期提取年、月、日、时、分、秒
SELECT 
	DATE_FORMAT(CURRENT_TIMESTAMP,'%Y') AS yr,
	DATE_FORMAT(CURRENT_TIMESTAMP,'%m') AS mon,
	DATE_FORMAT(CURRENT_TIMESTAMP,'%d') AS dy,
	DATE_FORMAT(CURRENT_TIMESTAMP,'%k') AS hr,
	DATE_FORMAT(CURRENT_TIMESTAMP,'%i') AS min,
	DATE_FORMAT(CURRENT_TIMESTAMP,'%s') AS sec
FROM t1;

-- 当前月份的第一天和最后一天
SELECT
	DATE_ADD(CURRENT_DATE,INTERVAL -DAY(CURRENT_DATE)+1 DAY) AS first_day,
	LAST_DAY(CURRENT_DATE) AS last_day
FROM t1;

-- 列出今年的每一个星期五的日期
-- YEAR(ADDDATE(x.dy,INTERVAL t500.id-1 DAY)) = x.yr 用于判定是今年
SELECT yr,DAYNAME(yr)
FROM (
	SELECT ADDDATE(x.dy,INTERVAL t500.id-1 DAY) yr
	FROM (
		SELECT dy,YEAR(dy) yr
		FROM (
			SELECT 
				ADDDATE(
					ADDDATE(CURRENT_DATE,
						INTERVAL -DAYOFYEAR(CURRENT_DATE) DAY),
					INTERVAL 1 DAY
				) AS dy
			FROM t1
			) tmp1
		) x,
		t500
	WHERE YEAR(ADDDATE(x.dy,INTERVAL t500.id-1 DAY)) = x.yr
	) tmp2
WHERE DAYNAME(yr) = 'Friday';

-- 找出当前月份的第一个星期一和最后一个星期一
-- SIGN(DAYOFWEEK(dy)-2) 对于 0 的话，意味着这一天为星期一 DAYOFWEEK的顺序为 日一二...
SELECT first_monday,
	CASE MONTH(ADDDATE(first_monday,28))
		WHEN mth THEN ADDDATE(first_monday,28)
		ELSE ADDDATE(first_monday,21)
	END AS last_monday
FROM (
	SELECT dy,DAYOFWEEK(dy),SIGN(DAYOFWEEK(dy)-2),
		CASE SIGN(DAYOFWEEK(dy)-2)
			WHEN 0 THEN dy
			WHEN -1 THEN ADDDATE(dy,ABS(DAYOFWEEK(dy)-2))
			WHEN 1 THEN ADDDATE(dy,(7-(DAYOFWEEK(dy)-2)))
		END AS first_monday,
		mth
	FROM (
		SELECT
			ADDDATE(ADDDATE(CURRENT_DATE,-DAY(CURRENT_DATE)),1) dy,
			MONTH(CURRENT_DATE) mth
		FROM t1
		) x
	) y;

-- 生成日历
-- DATE_FORMAT(y.dy,'%w') 的顺序为 一二三...六日
-- 最后使用周数做了一个行转列
SELECT 
	MAX(CASE z.dw WHEN 2 THEN z.dm END) AS Mo,
	MAX(CASE z.dw WHEN 3 THEN z.dm END) AS Tu,
	MAX(CASE z.dw WHEN 4 THEN z.dm END) AS We,
	MAX(CASE z.dw WHEN 5 THEN z.dm END) AS Th,
	MAX(CASE z.dw WHEN 6 THEN z.dm END) AS Fr,
	MAX(CASE z.dw WHEN 7 THEN z.dm END) AS Sa,
	MAX(CASE z.dw WHEN 1 THEN z.dm END) AS Su
FROM (
	SELECT 
		DATE_FORMAT(y.dy,'%u') AS wk,
		DATE_FORMAT(y.dy,'%d') AS dm,
		DATE_FORMAT(y.dy,'%w')+1 AS dw
	FROM (
		SELECT ADDDATE(x.dy,t100.id-1) dy,
			mth
		FROM (
			SELECT ADDDATE(CURRENT_DATE,-DAYOFMONTH(CURRENT_DATE)+1) AS dy,
				DATE_FORMAT(ADDDATE(CURRENT_DATE,-DAYOFMONTH(CURRENT_DATE)+1),'%m') AS mth
			FROM t1
			) x,
			t100
		WHERE t100.id <= 31
			AND DATE_FORMAT(ADDDATE(x.dy,t100.id-1),'%m') = x.mth
		) y
	) z
GROUP BY z.wk
ORDER BY z.wk

-- 列出一年中的每个季度的开始日期和结束日期
SELECT 
	QUARTER(ADDDATE(dy,-1)) AS QTR,
	DATE_ADD(dy,INTERVAL -3 MONTH) AS Q_start,
	ADDDATE(dy,-1) Q_end
FROM (
	SELECT DATE_ADD(dy,INTERVAL (3*id) MONTH) dy
	FROM (
		SELECT id,ADDDATE(CURRENT_DATE,-DAYOFYEAR(CURRENT_DATE)+1) dy
		FROM t500
		WHERE id <= 4
		) x
	) y;
	
-- 1980-1983年每个月份新入职的员工人数
-- 数据不全，只有一半数据
SELECT z.mth,COUNT(e.hiredate) AS num_hired
FROM (
	SELECT DATE_ADD(min_hd,INTERVAL t500.id-1 MONTH) mth
	FROM (
		SELECT min_hd,DATE_ADD(max_hd,INTERVAL 11 MONTH) max_hd
		FROM (
			SELECT 
				ADDDATE(MIN(hiredate),-DAYOFYEAR(MIN(hiredate))+1) min_hd,
				ADDDATE(MAX(hiredate),-DAYOFYEAR(MAX(hiredate))+1) max_hd
			FROM emp
			) x
		) y,
		t500
	WHERE DATE_ADD(min_hd,INTERVAL t500.id-1 MONTH) <= max_hd
	) z
LEFT JOIN emp e
ON (z.mth = ADDDATE(DATE_ADD(LAST_DAY(e.hiredate),INTERVAL -1 MONTH),1))
GROUP BY z.mth;

-- 依据特定时间单位检索数据
SELECT ename 
FROM emp
WHERE MONTHNAME(hiredate) IN ('February','December')
	OR DAYNAME(hiredate) = 'Tuesday';
	
-- 查相同月份和相同星期入职的员工
SELECT
	CONCAT(a.ename,' was hired on the same month and weekday as ',b.ename) AS msg
FROM emp a,emp b
WHERE DATE_FORMAT(a.hiredate,'%w%M') = DATE_FORMAT(b.hiredate,'%w%M')
	AND a.empno < b.empno
ORDER BY a.ename;

-- ------------------------------ 第10章 区间查询--------------------------------------
-- 计算同一组的行之间的差值，同一部门丽不同员工之间的工资差距
-- 差距指的是，当前员工sal和入职日期紧随其后的那个员工sal之间的差值
-- 先取出下一个日期 x.hiredate > e.hiredate 如果以日期为条件，取出下一个sal
-- 这里要保证hiredate唯一，要不会出错
SELECT
	deptno,ename,hiredate,sal,
	COALESCE(CAST(sal-next_sal AS CHAR(10)),'N/A') AS diff
FROM 
	(
	SELECT 
		e.deptno,
		e.ename,
		e.hiredate,
		e.sal,
		(
		SELECT MIN(sal) 
		FROM emp d 
		WHERE 
			d.deptno = e.deptno 
			AND 
			d.hiredate = 
				(
				SELECT MIN(hiredate) 
				FROM emp x
				WHERE 
					e.deptno = x.deptno 
					AND 
					x.hiredate > e.hiredate
				)
		) AS next_sal
	FROM emp e
	) y
ORDER BY deptno,hiredate;

-- 查一系列在时间上连续的项目
SELECT 
	p1.proj_id,
	p1.proj_start,
	p1.proj_end
FROM project p1,project p2
WHERE p1.proj_end = p2.proj_start;

-- 定位连续区间，返回区间段
SELECT 
	proj_grp,
	MIN(proj_start) AS proj_start,
	MAX(proj_end) AS proj_end
FROM (
	SELECT
		a.proj_id,
		a.proj_start,
		a.proj_end,
		(
			SELECT SUM(b.flag) 
			FROM view_project b 
			WHERE b.proj_id <= a.proj_id
		) AS proj_grp
	FROM view_project a
	) x
GROUP BY proj_grp;