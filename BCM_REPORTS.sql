CREATE OR REPLACE PACKAGE BCM_REPORTS AUTHID CURRENT_USER AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  PROCEDURE Question4;
  PROCEDURE Question5;
  PROCEDURE Question6;

END BCM_REPORTS;
/


CREATE OR REPLACE PACKAGE BODY BCM_REPORTS AS

  PROCEDURE Question4 IS cursor data1 is
  
    -- TODO: Implementation required for PROCEDURE BCM_REPORTS.Question4
    SELECT CAST(SUBSTR(di.ORDER_REF,3,3) AS NUMBER) || '|' || -- as "Order Reference" 
    SUBSTR(TO_CHAR(o.ORDER_DATE),4,6) || '|' || --as "Order Period",    
    initcap(s.SUPPLIER_NAME) || '|' || -- as "Supplier Name",
    TRIM(TO_CHAR(o.ORDER_TOTAL_AMOUNT,'99,999,999.99')) || '|' || -- as "Order Total Amount",
    o.ORDER_STATUS || '|' || -- as "Order Status",
    di.LEGACY_INVOICE_REF || '|' || -- as "Invoice Reference",
    TRIM(TO_CHAR((SELECT SUM(nvl(temp.INVOICE_AMOUNT,0)) from BCM_INVOICE temp WHERE temp.LEGACY_INVOICE_REF=di.LEGACY_INVOICE_REF),'99,999,999.99')) || '|' || -- as "Invoice Total Amount",
    CASE
      WHEN EXISTS (SELECT temp.INVOICE_AMOUNT FROM BCM_INVOICE temp WHERE temp.ORDER_REF=di.ORDER_REF AND nvl(temp.INVOICE_STATUS,'')='')
      THEN 'To verify'
      WHEN EXISTS (SELECT temp.INVOICE_AMOUNT FROM BCM_INVOICE temp WHERE temp.ORDER_REF=di.ORDER_REF AND temp.INVOICE_STATUS='Pending')
      THEN 'To follow up'
      ELSE
      'OK'
    END
    as FullSTR
    --di.ORDER_REF
    FROM
    (SELECT
    
    DISTINCT ORDER_REF,LEGACY_INVOICE_REF
    
    FROM BCM_INVOICE) di
    INNER JOIN BCM_ORDER o
    ON o.ORDER_REF = di.ORDER_REF
    INNER JOIN BCM_SUPPLIER s
    ON s.SUPPLIER_REF = o.SUPPLIER_REF
    
    ORDER BY o.ORDER_DATE DESC;
  BEGIN
    dbms_output.put_line('Order Reference|Order Period|Supplier Name|Order Total Amount|Order Status|Invoice Reference|Invoice Total Amount|Action');
    FOR c1rec IN data1 LOOP				
        dbms_output.put_line(c1rec.FullSTR);
			END LOOP;
  
  END Question4;
  
  PROCEDURE Question5 IS cursor data1 is
  
    select  TO_CHAR(CAST(SUBSTR(temp.ORDER_REF,3,3) AS NUMBER))|| '|' || 
            TO_CHAR(temp.ORDER_DATE,'MONTH DD,YYYY') || '|' || 
            UPPER(s.SUPPLIER_NAME) || '|' || 
            temp.ORDER_STATUS || '|' || 
            listagg(invoice.INVOICE_REF,',') within group(order by temp.ORDER_REF) 
            
            as FullSTR 
    from
    (
    select 
    (row_number() over ( order by ORDER_TOTAL_AMOUNT DESC, ORDER_REF )) as r1
    ,ORDER_TOTAL_AMOUNT, ORDER_REF,SUPPLIER_REF,BCM_ORDER.ORDER_DATE,ORDER_STATUS
    FROM BCM_ORDER 
    WHERE ORDER_REF_PARENT IS NULL
    ) temp
    INNER JOIN BCM_INVOICE invoice
    ON invoice.ORDER_REF = temp.ORDER_REF
    INNER JOIN BCM_SUPPLIER s
    ON s.SUPPLIER_REF = temp.SUPPLIER_REF
    
    where temp.r1 =3
    GROUP BY CAST(SUBSTR(temp.ORDER_REF,3,3) AS NUMBER),temp.ORDER_DATE,UPPER(s.SUPPLIER_NAME),temp.ORDER_STATUS
    ;
  
  BEGIN
    dbms_output.put_line('Order Reference|Order Date|Supplier Name|Order Total Amount|Order Status|Invoice References');
    FOR c1rec IN data1 LOOP				
        dbms_output.put_line(c1rec.FullSTR);
    END LOOP;
  
  END Question5;
  
  PROCEDURE Question6 IS cursor data1 is
  
    SELECT
      SUPPLIER_NAME || '|' ||
      SUPP_CONTACT_NAME || '|' ||
      
          
          TRIM(REPLACE(TO_CHAR(CAST(CASE INSTR(SUPP_CONTACT_NUMBER,',',1) 
          WHEN 0 THEN SUPP_CONTACT_NUMBER
          ELSE SUBSTR(SUPP_CONTACT_NUMBER,1,INSTR(SUPP_CONTACT_NUMBER,',',1)-1)
          END  AS NUMBER),'9999,9999'),',','-'))
           
          
          || '|' ||
      trim( nvl(
            replace( 
              TO_CHAR(
                      CASE INSTR(SUPP_CONTACT_NUMBER,',',1)
                        WHEN 0 THEN NULL
                        ELSE SUBSTR(SUPP_CONTACT_NUMBER,INSTR(SUPP_CONTACT_NUMBER,',',1)+1,LENGTH(SUPP_CONTACT_NUMBER))
                        END
                      ,'9999,9999'
                      )
              ,',','-')
            ,''
              
            )
            ) || '|' ||
      COUNT(o.ORDER_REF) || '|' ||
      TRIM(TO_CHAR(SUM(o.ORDER_TOTAL_AMOUNT),'99,999,999.99'))  as FullSTR
    FROM BCM_SUPPLIER s
    INNER JOIN BCM_ORDER o
    ON o.SUPPLIER_REF = s.SUPPLIER_REF  
    WHERE o.ORDER_REF_PARENT IS NULL
    GROUP BY s.SUPPLIER_REF,SUPPLIER_NAME,SUPP_CONTACT_NAME,SUPP_CONTACT_NUMBER
    ;

  BEGIN
    
    dbms_output.put_line('Supplier Name|Supplier Contact Name|Supplier Contact No. 1|Supplier Contact No. 2|Total Orders|Order Total Amount');
    FOR c1rec IN data1 LOOP				
        dbms_output.put_line(c1rec.FullSTR);
    END LOOP;
  

  END Question6;

END BCM_REPORTS;
/
