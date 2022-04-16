USE deeprespredDB;

--Parameter Table

INSERT INTO deeprespredDB.parameter (idParameter, name, description, value) VALUES (1, 'maxRequestsxDay', 'Maximum quantity of requests by user per day', 30);
INSERT INTO deeprespredDB.parameter (idParameter, name, description, value) VALUES (2, 'maxResidues', 'Maximum quantity of residues in a sequence', 515);
INSERT INTO deeprespredDB.parameter (idParameter, name, description, value) VALUES (3, 'cpuNumber', 'Quantity of server cpus assigned to prediction process', 4);

--StatusRequest Table

INSERT INTO deeprespredDB.statusrequest (idStatus, name) VALUES (1, 'REGISTERED');
INSERT INTO deeprespredDB.statusrequest (idStatus, name) VALUES (3, 'PROCESSING');
INSERT INTO deeprespredDB.statusrequest (idStatus, name) VALUES (4, 'FINALIZED');
INSERT INTO deeprespredDB.statusrequest (idStatus, name) VALUES (5, 'ERROR');

COMMIT;