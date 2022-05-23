USE deeprespredDB;

#----Parameter Table

INSERT INTO deeprespredDB.parameter (name, description, value) VALUES ('maxRequestsxDay', 'Maximum quantity of requests by user per day', 30);
INSERT INTO deeprespredDB.parameter (name, description, value) VALUES ('maxResidues', 'Maximum quantity of residues in a sequence', 515);
INSERT INTO deeprespredDB.parameter (name, description, value) VALUES ('cpuNumber', 'Quantity of server cpus assigned to prediction process', 4);

#----StatusRequest Table
INSERT INTO deeprespredDB.statusrequest (name) VALUES ('REGISTERED');
INSERT INTO deeprespredDB.statusrequest (name) VALUES ('IN PROCESS');
INSERT INTO deeprespredDB.statusrequest (name) VALUES ('PROCESSING');
INSERT INTO deeprespredDB.statusrequest (name) VALUES ('FINALIZED');
INSERT INTO deeprespredDB.statusrequest (name) VALUES ('ERROR');

COMMIT;