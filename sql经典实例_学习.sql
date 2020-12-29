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
SELECT deptno,comm FROM emp WHERE deptno IN (10,30) ORDER BY 1;