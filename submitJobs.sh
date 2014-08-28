subjects="A111907G
D030208S
L030208D
R030308W
S102907D
W021808H
M042507D
R042507M
S042507C
S042507H
C111507D
C111907L
D010908G
E011108K
E122007P
M012108K
M032408K
M110707N
V020808H
V061908W
V020408W
"

for subj in $subjects
do
	qsub -l h_vmem=12.2G,s_vmem=12G -M bock.andrew@gmail.com -v SUBJECT=$subj, run_MVPA_aud_tac.sh
    qsub -l h_vmem=12.2G,s_vmem=12G -M bock.andrew@gmail.com -v SUBJECT=$subj, run_MVPA_aud_vis.sh
    qsub -l h_vmem=12.2G,s_vmem=12G -M bock.andrew@gmail.com -v SUBJECT=$subj, run_MVPA_tac_vis.sh
    qsub -l h_vmem=12.2G,s_vmem=12G -M bock.andrew@gmail.com -v SUBJECT=$subj, run_MVPA_aud_tac_vis.sh
    qsub -l h_vmem=12.2G,s_vmem=12G -M bock.andrew@gmail.com -v SUBJECT=$subj, run_MVPA_aud_tac_vis_rev.sh
done

