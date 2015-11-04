--Query to mimic Create Lists query, working around bug with "Money Owed" field in Create Lists (introduced in Sierra 2.0 Service Pack 3)
-- select fields with alias AS to define field headers
SELECT
 p.record_num AS "Patron Number",
 -- concatenate name from database fields
 TRIM(pn.last_name||', '||
  pn.first_name||' '||
  pn.middle_name) AS "Patron Name",
 p.barcode AS "Patron Barcode",
 p.owed_amt AS "Owed Amount",
 p.expiration_date_gmt AS "Expiration Date",
 p.ptype_code AS "Patron Type",
 email.field_content AS "Email",
 -- bursar hold notes
 pnote.field_content AS "Patron Note"
-- put the data into a temporary table for export to file
INTO TEMP patron_export
FROM 
 sierra_view.patron_view AS p
JOIN
  sierra_view.varfield AS pnote
  ON
  pnote.record_id = p.id
  AND
  pnote.varfield_type_code = 'x'
JOIN
 sierra_view.patron_record_fullname AS pn
ON
 pn.patron_record_id = p.id
JOIN
 sierra_view.patron_record pr
ON
 pr.record_id = p.id
JOIN 
 sierra_view.varfield email
ON
 email.varfield_type_code = 'z' AND email.record_id = pr.record_id
WHERE 
-- patron owes $10 or more
p.owed_amt >= 10 
AND
-- patron is not yet expired
p.expiration_date_gmt > CURRENT_TIMESTAMP(0)
ORDER BY 2;
--Send output to a CSV file on the network so Circulation Supervisor can access it
\COPY patron_export TO '\\networklocation\patron_gt10dollars_export.csv' WITH csv header;
\q;