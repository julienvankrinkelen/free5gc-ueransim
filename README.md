# free5gc-ueransim-microk8s

A simple bash script to deploy Free5gc and UERANSIM on microk8s.

## Deployment
```
git clone git@github.com:julienvankrinkelen/free5gc-ueransim.git && cd free5gc-ueransim
chmod 777 Deploy_free5gc_ueransim_microk8s.sh
```

Then open the script and change user value by the name of the current user. By default, it is set to root.
Now you can run the script
```
./Deploy_free5gc_ueransim_microk8s.sh
```
When it has finished running, you can check the status of the pods by running

```
watch sudo microk8s kubectl get pods -n free5gc
```
Once the pods have finished deploying, you can go the free5gc webUI and create a user...

Login: admin 

Password: free5gc 

```
microk8s kubectl port-forward --namespace free5gc svc/webui-service 5000:5000
```
