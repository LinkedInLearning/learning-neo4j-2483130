//Delete data (if any)
MATCH (n) DETACH DELETE n;

//Add constraints
CREATE CONSTRAINT IF NOT EXISTS ON (student:Student) ASSERT student.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS ON (state:State) ASSERT state.name IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS ON (gradYear:Year) ASSERT gradYear.value IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS ON (program:Program) ASSERT program.name IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS ON (country:Country) ASSERT country.name IS UNIQUE;

//Load data. We will use several statements to minimise eager queries and flat file downloads. 
//Note that this may not be how you'd typically do this!
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/LinkedInLearning/learning-neo4j-2483130/main/roux.csv?token=GHSAT0AAAAAABU2HBI3B2IHKK22MTAJ7WWMYUTJSLQ" AS row
CREATE  (student:Student {id:row.ID, last:row.LAST, first:row.FIRST, email:row.EMAIL, newsletter:row.NEWSLETTER,
	state:row.STATE, grad:tointeger(row.GRADYEAR), prog:row.PROGRAM, country:row.STUDIEDIN, gpa:tofloat(row.GPA)});

//Create and link the State note
MATCH (student:Student)
MERGE (state:State {name:student.state})
WITH student, state
CREATE (student)-[:FROM]->(state)
REMOVE student.state;

//Create and link the Year node
MATCH (student:Student)
MERGE (grad:Year {value:student.grad})
WITH student, grad
CREATE (student)-[:GRADUATED_IN]->(grad)
REMOVE student.grad;

//Create and link the Program node
MATCH (student:Student)
MERGE (prog:Program {name:student.prog})
WITH student, prog
CREATE (student)-[:STUDIED]->(prog)
REMOVE student.prog;

//Create and link the Country node. Skip the n/a values
MATCH (student:Student)
	WHERE student.country <> 'n/a'
MERGE (country:Country {name:student.country})
WITH student, country
CREATE (student)-[:STUDIED_ABROAD_IN]->(country)
REMOVE student.country;

//Create grade categories (Grade node) and link with GPA score as relationship property
WITH [[2.00,2.33,'C'],[2.33,2.67,'C+'],[2.67,3.00,'B'],[3.00,3.33,'B+'],[3.33,3.67,'A-'],[3.67,4.00,'A'],[4.00,4.00,'A+']] AS ranges
UNWIND ranges AS range
CREATE (:Grade {from:range[0], to:range[1], grade:range[2]});

MATCH (student:Student),
      (grade:Grade)
	WHERE student.gpa>=grade.from AND student.gpa < grade.to
CREATE (student)-[:OBTAINED {gpa:student.gpa}]->(grade)
REMOVE student.gpa;